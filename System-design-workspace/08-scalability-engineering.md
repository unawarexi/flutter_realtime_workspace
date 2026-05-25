# 08 — Scalability Engineering
# TeamSpot: Horizontal Scaling, Bottleneck Analysis, Capacity Planning & Load Design

---

## 1. Scaling Philosophy

Scaling is not a single event — it is an ongoing engineering discipline. TeamSpot's approach is:

1. **Measure first** — never optimize without data (Prometheus + OpenTelemetry)
2. **Scale the bottleneck** — identify the constraint, fix that constraint only
3. **Stateless services** — application tier scales horizontally by default
4. **State lives in infrastructure** — MongoDB, Redis, Kafka own all durable state
5. **Async everything non-critical** — move work off the request path via queues

---

## 2. Architecture Scaling Tiers

### Tier 0 — Single Server (0–10k MAU)
```
Client → Nginx → Node.js (1 instance) → MongoDB Atlas → Redis Cloud
```
- Single Kubernetes pod
- Managed Atlas + Redis Cloud
- All services in docker-compose
- Cost: ~$50–150/month

### Tier 1 — Horizontal API (10k–500k MAU)
```
Client → Cloudflare CDN → Nginx Load Balancer
              → Node.js Pod 1 ─┐
              → Node.js Pod 2 ──→ MongoDB (replica set) → Redis Cluster
              → Node.js Pod 3 ─┘        ↓
                                    Kafka Cluster (3 brokers)
```
- K8s Deployment: 3 replicas, RollingUpdate
- Redis adapter for Socket.IO (multi-node WebSocket fanout)
- Kafka partitioned by tenantId for ordered processing
- Cost: ~$500–2000/month

### Tier 2 — Domain Extraction (500k–10M MAU)
```
API Gateway → Auth Service (stateless, high-volume)
            → Core API Monolith (K8s, 10+ replicas)
            → AI Worker Pool (GPU-enabled, isolated)
            → WebSocket Gateway (sticky session nodes)
            → Media Processing Service (CPU-intensive)
```
- Extract auth, AI, and WebSocket into separate deployments
- MongoDB sharding by tenantId
- Redis Cluster (6 nodes minimum)
- Kafka: 12+ partitions per hot topic

### Tier 3 — Global Distribution (10M+ MAU)
```
Regional edges: US-East, US-West, EU-West, AP-Southeast
  Each region: API cluster + MongoDB replica + Redis + Kafka
  Global: MongoDB Global Cluster (zone-pinned writes)
           CloudFlare R2 (media CDN)
           Qdrant distributed (vector search)
```

---

## 3. Stateless Application Design

The Node.js API tier is **fully stateless**. No in-memory session state, no local file writes, no sticky sessions required for HTTP.

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

The only exception is Socket.IO connection state — handled via `@socket.io/redis-adapter` which synchronizes events across all nodes.

---

## 4. Database Scaling Strategy

### MongoDB Scaling Path

**Phase 1: Replica Set (default)**
```
Primary (writes + reads)
  ├── Secondary 1 (reads + failover)
  └── Secondary 2 (reads + failover)
```
- All writes → Primary
- Analytics/reporting reads → Secondary with `readPreference: secondary`
- Automated failover < 30 seconds

**Phase 2: Indexing Strategy (critical before sharding)**

Every high-volume collection must have compound indexes covering tenant context:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

**Phase 3: Sharding (when single replica set saturates)**
- Shard key: `{ tenantId: 1, _id: 1 }` — hashed tenantId for even distribution
- Zone sharding: pin large enterprise tenants to dedicated shards
- Hot tenant mitigation: move high-traffic tenants to isolated shards

### Redis Scaling Path

```
Phase 1: Single Redis (up to ~50k concurrent users)
Phase 2: Redis Sentinel (HA, automatic failover)
Phase 3: Redis Cluster (6 nodes, horizontal + HA)
  - Hash slots distribute keys across 3 master nodes
  - Each master has 1 replica
  - Pub/sub topics route to all nodes via Redis Cluster pub/sub
```

### Kafka Scaling Path

```
Phase 1: 3 brokers, 6 partitions per topic
  - Partition key: tenantId (consistent routing)
  - Replication factor: 3 (survives 1 broker failure)

Phase 2: Scale partitions (not brokers) when consumer lag grows
  - teamspot.tasks.events: 12 partitions (high volume)
  - teamspot.ai.stream: 24 partitions (GPU workers)
  - teamspot.messages: 24 partitions (chat fanout)
  - teamspot.audit: 6 partitions (lower volume, ordered)

Phase 3: Kafka MirrorMaker2 for cross-region replication
```

---

## 5. Bottleneck Analysis

### Expected Bottleneck Order (by exhaustion sequence)

| Rank | Component | Bottleneck Trigger | Mitigation |
|------|-----------|--------------------|------------|
| 1 | **MongoDB queries** | Missing indexes, N+1 patterns | Compound indexes + BaseRepository pagination |
| 2 | **Redis pub/sub** | WebSocket fanout at high concurrency | Redis Cluster + connection pooling |
| 3 | **Node.js Event Loop** | Blocking synchronous code in I/O path | async/await, offload CPU work to workers |
| 4 | **Kafka consumer lag** | AI embedding queue backup | Scale AI worker pod replicas |
| 5 | **LiveKit SFU** | Video room capacity | LiveKit horizontal scaling (separate infra) |
| 6 | **Qdrant vector search** | Slow semantic queries | HNSW index tuning, payload indexing |
| 7 | **Cloudinary CDN** | Large media upload volume | Multipart + chunked uploads, CDN edge cache |

### N+1 Query Prevention

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 6. Caching Architecture

### Cache-Aside Pattern (standard)
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Cache Invalidation Strategy
```
Write-through: On every mutation, invalidate related cache keys
  - Task updated → invalidate task:id + task-list:projectId + project:id (progress)
  - User profile updated → invalidate user:id + team-members:teamId

Pattern invalidation: Redis SCAN + DEL for collection-level invalidations
  - SCAN 0 MATCH "project:*:tasks" — invalidate all task caches for project
  
TTL-based expiry (last resort):
  - USER_PROFILE: 300s, WORKSPACE: 120s, TASK_LIST: 30s
```

### What to Cache vs. Never Cache

| Cache This | Never Cache |
|------------|-------------|
| User profiles (read-heavy) | Permission checks (must be real-time) |
| Organization/workspace config | Billing state (must be Stripe canonical) |
| Project metadata | AI responses (always fresh) |
| Template HTML | Audit log entries |
| Search results (60s) | Active WebSocket sessions |

---

## 7. Pagination Strategy

All list endpoints use **cursor-based pagination** (not offset). Offset pagination breaks under high-frequency writes (items shift between pages).

> **See** [`Backend_Realtime_Workspace/core/utils/pagination.js`](../Backend_Realtime_Workspace/core/utils/pagination.js) — `parsePagination()`, `buildCursorFilter()`, `encodeCursor()`, `decodeCursor()` — offset + cursor pagination helpers

---

## 8. Rate Limiting Architecture

Multi-layer rate limiting prevents abuse without blocking legitimate users:

```
Layer 1: Nginx (global, IP-based)
  - 100 req/s per IP for API
  - 10 req/s per IP for auth endpoints

Layer 2: Express (application-level, user/IP)
  RateLimits.API:    300 req/15min per user
  RateLimits.AUTH:   20 req/15min per IP
  RateLimits.AI_CHAT: 30 req/min per user
  RateLimits.UPLOAD: 20 req/min per user
  RateLimits.MESSAGE: 120 req/min per user

Layer 3: Business logic (per-tenant quotas)
  WorkspaceConfig.MAX_MEMBERS: 1000
  WorkspaceConfig.MAX_CHANNELS: 500
  StorageConfig.RETENTION_DAYS by plan tier
```

### Token Bucket Algorithm (Redis-backed)

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

---

## 9. Throughput Estimation

At 1B DAU target:
```
Peak concurrent users: ~100M (10% of DAU active at peak)
Average requests/user/hour: 50
Peak RPS: 100M × 50 / 3600 = ~1.4M RPS

Distribution:
  - API reads (cached): 60% = 840k RPS → Nginx + Redis handles
  - API writes: 20% = 280k RPS → application + MongoDB
  - WebSocket events: 15% = 210k RPS → Socket.IO + Kafka fanout
  - AI queries: 5%  = 70k RPS  → AI worker pools (GPU-backed)

MongoDB write capacity: 100k WPS per shard
  → Requires ~3 shards for writes, ~10 for reads

Redis operations: 500k ops/sec per Redis Cluster node
  → 6-node cluster handles 3M ops/sec

Kafka throughput: 500MB/s per broker
  → 3 brokers handle 1.5GB/s of events
```

These numbers require multi-region active-active deployment. The current single-region modular monolith is the correct starting point — extract and scale components as these limits are approached.
