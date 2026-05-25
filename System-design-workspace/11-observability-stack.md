# 11 — Observability Stack
# TeamSpot: Logging, Metrics, Distributed Tracing & Alerting

---

## 1. The Three Pillars of Observability

Observability answers: **"Why is my system behaving this way right now?"**

| Pillar | Tool | Purpose |
|--------|------|---------|
| **Logs** | Pino + structured JSON | What happened, in what order |
| **Metrics** | Prometheus + Grafana | How is the system performing over time |
| **Traces** | OpenTelemetry + OTLP | Why did this specific request take 800ms |

These three are complementary, not redundant. A 500 error tells you *something* broke (log), your error rate graph shows the pattern (metric), and the trace shows you exactly which database query caused it.

---

## 2. Structured Logging (Pino)

### Logger Architecture

> **See** [`Backend_Realtime_Workspace/agent/runtime/agent-executor.js`](../Backend_Realtime_Workspace/agent/runtime/agent-executor.js) — `AgentExecutor` — LangGraph `StateGraph` ReAct loop, `ToolRegistry`, `ModelFallback`

### Request Correlation ID

Every HTTP request gets a unique `requestId` injected at the entry point:

> **See** [`Backend_Realtime_Workspace/core/utils/id-generator.js`](../Backend_Realtime_Workspace/core/utils/id-generator.js) — ULID / `generateId()` — lexicographically sortable event IDs

### Log Schema

Every log entry is valid JSON with these fields:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Log Levels by Use Case

| Level | When to Use | Example |
|-------|-------------|---------|
| `error` | Unhandled exceptions, data corruption, security violations | `AI tool execution failed` |
| `warn` | Expected failures, degraded mode, retry exhausted | `Redis cache miss, falling back to DB` |
| `info` | Normal business events (audit trail) | `User signed in`, `Task created` |
| `debug` | Troubleshooting details (disabled in production) | SQL query parameters |
| `trace` | Deep internals (never in production) | Middleware chain timing |

---

## 3. Prometheus Metrics

### Middleware Integration

> **See** [`Backend_Realtime_Workspace/observability/prometheus.js`](../Backend_Realtime_Workspace/observability/prometheus.js) — Prometheus metrics — `httpRequestDuration`, `httpRequestTotal`, default Node.js metrics

### Key Business Metrics

> **See** [`Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js`](../Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js) — `LiveKitService.createRoom()`, `.generateToken()` — WebRTC SFU room management

### Metrics Endpoint

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

### Grafana Dashboard Panels

```
Infrastructure Dashboard:
  - API RPS and p50/p95/p99 latency
  - Error rate (4xx, 5xx) over time
  - Pod CPU/memory utilization
  - MongoDB query latency histogram
  - Redis hit rate and memory usage
  - Kafka consumer lag per topic

Business Dashboard:
  - Active users (WebSocket connections)
  - Tasks created/completed per hour
  - AI queries per minute + token burn rate
  - Document uploads per hour
  - Meeting room occupancy
  - Error budget consumption (SLO burn rate)

Security Dashboard:
  - Auth failure rate per IP
  - Rate limit rejections per user
  - Suspicious request patterns
  - Prompt injection attempts (AI governance counter)
```

---

## 4. Distributed Tracing (OpenTelemetry)

### Tracing Architecture

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

### Trace Context Propagation

```
HTTP Request arrives with:
  traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

Express auto-instruments → creates root span

  Root Span: POST /api/v1/tasks
    ↓
    Child Span: firebaseAuthMiddleware (Firebase token verify)
    Child Span: MongoDB findOne (tenantId validation)
    Child Span: TaskService.create
      ↓
      Child Span: Task.save() → MongoDB insert
      Child Span: kafka.publishEvent → teamspot.tasks.events
      Child Span: redis.setex → cache task
    Child Span: ApiResponse.created()
```

Trace IDs are included in every log entry, enabling log-to-trace correlation in Grafana.

---

## 5. Sentry Error Tracking

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Sentry vs Logs vs Metrics — When to Use Which

| Scenario | Tool |
|----------|------|
| Unexpected exception | Sentry (with stack trace + user context) |
| Expected error (validation fail) | Log at info, no Sentry |
| Performance degradation | Prometheus metric + Grafana alert |
| Request tracing | OpenTelemetry trace |
| Business event | Structured log (Pino) |
| Security incident | Sentry + log + alert |

---

## 6. Alerting Strategy

### Alert Severity Tiers

```
P1 — Critical (page on-call immediately, wake at 2am):
  - API error rate > 5% for > 2 minutes
  - No healthy pods in namespace (all health checks failing)
  - MongoDB primary down and failover not completed in 60s
  - Data breach detection (Sentry security events)

P2 — High (page on-call during business hours):
  - API p95 latency > 1 second for > 5 minutes
  - Kafka consumer lag > 50k messages for > 10 minutes
  - Error budget 80% consumed for current month
  - Redis memory > 90%

P3 — Medium (notify team Slack channel, next business day):
  - AI service unavailable > 15 minutes
  - MongoDB query p99 > 500ms
  - Rate limit rejections spike > 1000/min
  - Failed webhook deliveries > 10% in hour

P4 — Info (log, no notification):
  - Cache hit rate drops below 80%
  - New tenant onboarded
  - Large file upload detected
```

### Alert Routing

```
Prometheus AlertManager → 
  P1/P2: PagerDuty → on-call engineer phone
  P3: Slack #incidents channel
  P4: Slack #observability channel
  
Sentry → 
  All errors: Slack #backend-errors
  Security events: Slack #security-alerts
```

---

## 7. Tracing AI Operations

AI agent operations require special observability because they involve non-deterministic, multi-step workflows:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

This enables:
- Per-tenant AI cost tracking
- Model performance comparison
- Token budget enforcement per plan tier
- Compliance audit trail for AI actions
