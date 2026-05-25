# 10 — Reliability Engineering
# TeamSpot: High Availability, Resilience Patterns, SLOs & Disaster Recovery

---

## 1. Reliability Philosophy

**Goal**: Users should never notice infrastructure problems. When things fail — and they will — the system degrades gracefully with partial functionality rather than complete outage.

The three pillars of reliability for TeamSpot:
1. **Redundancy** — every critical component has at least one standby
2. **Resilience** — failures are contained, not propagated
3. **Recoverability** — when something breaks, recovery is automated and fast

---

## 2. SLO / SLI / SLA Design

### Service Level Objectives

| Service | Availability SLO | Latency SLO (p95) | Error Rate SLO |
|---------|-----------------|-------------------|----------------|
| API (reads) | 99.9% | < 200ms | < 0.1% |
| API (writes) | 99.9% | < 500ms | < 0.1% |
| WebSocket | 99.5% | Connect < 1s | < 0.5% |
| AI Chat (SSE) | 99.0% | First token < 2s | < 1.0% |
| Video (LiveKit) | 99.5% | Room join < 3s | < 0.5% |
| Search | 99.5% | < 300ms | < 0.5% |
| Notifications (push) | 99.0% | Delivery < 5s | < 1.0% |

### Error Budget Calculation
```
99.9% availability = 8.76 hours downtime/year
99.5% availability = 43.8 hours downtime/year

Monthly error budget for 99.9% API:
  = 30 days × 24h × 60min × 0.1% = 43.2 minutes/month

When error budget is 50% consumed → alert
When error budget is 100% consumed → freeze non-critical deploys
```

---

## 3. Resilience Patterns

### Circuit Breaker Pattern

Prevents cascading failures when an external dependency (Kafka, Redis, AI service) degrades.

> **See** [`Backend_Realtime_Workspace/core/utils/retry.js`](../Backend_Realtime_Workspace/core/utils/retry.js) — `withRetry()`, `retryWithBackoff()`, `createRetryStrategy()` — exponential backoff with full jitter

### Bulkhead Pattern

Isolate failures to one subsystem — don't let AI slowness affect task API performance.

```
Resource pools are isolated per subsystem:
  MongoDB connection pool: 50 connections
  Redis connection pool: 20 connections
  AI HTTP client: 10 connections (separate Axios instance)
  Kafka producer: dedicated async
  
If AI service pool is exhausted → AI endpoints return 503
  → Task/Project/Chat APIs continue unaffected
```

### Graceful Degradation

> **See** [`Backend_Realtime_Workspace/core/utils/api-response.js`](../Backend_Realtime_Workspace/core/utils/api-response.js) — `ApiResponse.success()`, `ApiResponse.error()` — standardised HTTP response envelope

### Idempotency for Queue Consumers

Every event processed by Kafka/RabbitMQ workers includes an idempotency key:

> **See** [`Backend_Realtime_Workspace/core/utils/id-generator.js`](../Backend_Realtime_Workspace/core/utils/id-generator.js) — ULID / `generateId()` — lexicographically sortable event IDs

---

## 4. High Availability Architecture

### MongoDB Replica Set HA

```
Primary (reads + writes)  ←── driver auto-detects via replica set name
  │
  ├── Secondary 1 (sync)   ←── failover candidate (priority: 1)
  └── Secondary 2 (sync)   ←── failover candidate (priority: 1)
  
Failover scenario:
  Primary crashes → Secondaries elect new primary in < 30 seconds
  Application reconnects automatically (Mongoose retry logic)
  In-flight writes that weren't acknowledged → Mongoose retries
```

### Redis HA (Sentinel / Cluster)

```
Sentinel Mode (Phase 1):
  redis-sentinel monitors master
  On master failure: promotes replica in < 10s
  Clients use Sentinel URL → auto-discover new master

Cluster Mode (Phase 2):
  3 masters + 3 replicas
  Each master owns 1/3 of key space (hash slots)
  Master failure → replica promoted automatically
  Client uses cluster-aware ioredis client
```

### Kubernetes Pod Distribution

> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

This ensures 3 pods run on 3 different EC2 nodes. If one node fails, only 1/3 of capacity is lost — K8s immediately schedules a replacement pod.

---

## 5. Graceful Shutdown

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

Why this matters: K8s sends SIGTERM 30 seconds before force-killing. Without graceful shutdown, in-flight requests are dropped, database connections leak, Kafka consumers leave partitions unassigned.

---

## 6. Backup & Recovery Strategy

### MongoDB Backup

```
Production: MongoDB Atlas Continuous Backups
  - Point-in-time recovery (PITR) to any second in last 24 hours
  - Daily snapshots retained for 7 days
  - Weekly snapshots retained for 4 weeks
  - Monthly snapshots retained for 12 months

Recovery SLO:
  RPO (Recovery Point Objective): < 1 second (PITR)
  RTO (Recovery Time Objective): < 30 minutes (Atlas restore)
```

### Redis Backup

```
Redis AOF (Append-Only File) + RDB snapshots
  - AOF: every write appended to disk → RPO ≈ 0 seconds
  - RDB snapshot: every 60s → RPO ≈ 60 seconds

Note: Redis is a cache layer, NOT source of truth.
  If Redis is completely lost, application rebuilds cache from MongoDB.
  Actual data loss from Redis failure = 0.
```

### Kafka Message Retention

```
Kafka topic retention: 7 days (default)
  - All events replayable for 7 days
  - Consumer groups can reset offsets and reprocess
  - Audit topic retention: 90 days (compliance)
  
Use cases for replay:
  - Search indexing failed → replay documents.created events
  - Analytics aggregation bug → replay analytics.events
  - AI embedding job crashed → replay ai.rag_ingest events
```

---

## 7. Disaster Recovery Playbooks

### Scenario 1: MongoDB Primary Node Failure

```
Detection: Prometheus alert "mongodb_up == 0" for primary node
Response:
  1. Replica set automatically elects new primary (< 30s)
  2. Mongoose driver reconnects automatically
  3. Alert fires to on-call engineer
  4. Verify promotion: mongo --eval "rs.status()"
  5. Replace failed node in Atlas UI (or Terraform)
  6. Wait for resync (hours for large datasets)
  7. Confirm replica set has 3 healthy members

User impact: Write failures for ~30 seconds during election
Mitigation: retry.js with 3 attempts + 1s backoff absorbs most errors
```

### Scenario 2: Redis Complete Failure

```
Detection: Prometheus alert "redis_connected_clients == 0"
Response:
  1. Application degrades: cache-miss → MongoDB fallback (automatic)
  2. Presence/online-status unavailable (non-critical)
  3. Socket.IO pub/sub unavailable → WebSocket messages not cross-pod
  4. Alert on-call to restore Redis
  5. After restore: no data migration needed (cache rebuilds itself)

User impact: Slower API responses (no cache) + WebSocket cross-pod broken
Mitigation: All Redis calls wrapped in .catch(() => null) for reads
```

### Scenario 3: Kafka Cluster Failure

```
Detection: Kafka consumer lag shoots to max, then stops
Response:
  1. Event publishing fails → withRetry() buffers locally for 3 attempts
  2. After retry exhaustion → writes succeed to MongoDB but events lost
  3. Background workers stop processing (email, AI embedding, audit)
  4. Restore Kafka cluster (EKS managed via Terraform or Confluent Cloud)
  5. After restore: replay events from MongoDB audit trail
  6. Workers resume from stored offset (Kafka consumer group commits)

User impact: Delayed notifications/emails; AI indexing paused
Critical impact: None (all CRUD operations still work via MongoDB)
```

### Scenario 4: Full Region Failure

```
Detection: 100% API error rate from single region
Response:
  1. DNS failover via Cloudflare (manual or Traffic Manager rule)
  2. Point traffic to secondary region (or degrade to read-only mode)
  3. Secondary region may have up to X seconds of data lag
     (MongoDB Global Cluster zone-pinned writes have replication lag)
  4. Notify users of incident via status page
  5. Post-incident: full audit of data consistency

This requires multi-region setup (Phase 3 roadmap — not current)
```

---

## 8. Chaos Engineering Strategy

Proactively inject failures in staging to verify resilience:

```
Monthly Chaos Tests:
  1. Kill 1 of 3 API pods → verify HPA replaces, zero user impact
  2. Disconnect Redis → verify MongoDB fallback + reconnect
  3. Saturate Kafka consumer → verify message delivery under lag
  4. Inject 500ms latency to MongoDB → verify cache effectiveness
  5. Kill AI service → verify graceful degradation to non-AI response
  6. Flood upload endpoint → verify rate limiting + quota enforcement

Tools: Chaos Mesh (K8s), or manual kubectl delete pod
Runbook: each test has expected behavior documented before execution
```

---

## 9. Observability Integration with Reliability

Reliability is only achievable if you can measure it. See `12-observability-stack.md` for full details, but the reliability-specific metrics are:

```
Business metrics (directly tied to SLOs):
  - api_request_duration_seconds{quantile="0.95"} < 0.2
  - api_error_rate < 0.001
  - websocket_connection_failures_total (rate < 0.5%)
  - kafka_consumer_lag_sum (alert if lag > 10k for > 5 minutes)

Alerting thresholds:
  - Page on-call: error rate > 1% for > 2 minutes
  - Page on-call: API p95 > 1s for > 5 minutes
  - Warn: error budget 50% consumed in current month
  - Page: error budget 100% consumed
```
