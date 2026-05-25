# 15 — Engineering Philosophy & Coding Standards
# TeamSpot: Design Principles, Clean Architecture, SOLID & Technical Debt Management

---

## 1. Core Engineering Philosophy

TeamSpot is built on the principle that **good code is read more than it is written**. Every architectural decision optimizes for:

1. **Correctness** — the system does what it promises, especially under failure
2. **Clarity** — any engineer can understand any module in < 30 minutes
3. **Changeability** — requirements change; the code must accommodate this without rewrites
4. **Observability** — you can always answer "why is this broken?"

These four goals often conflict. When they do, prioritize in the order listed above.

---

## 2. Clean Architecture in TeamSpot

### Dependency Rule
Dependencies point **inward only**. The domain core has zero knowledge of HTTP, MongoDB, or Kafka.

```
             ┌──────────────────────────────────┐
             │           Routes (HTTP)           │  ← outermost
             ├──────────────────────────────────┤
             │         Controllers               │
             ├──────────────────────────────────┤
             │          Services                 │  ← business logic
             ├──────────────────────────────────┤
             │        Repositories               │
             ├──────────────────────────────────┤
             │    Models / Domain Entities       │  ← innermost
             └──────────────────────────────────┘
             
Outer layers depend on inner layers. NEVER the reverse.
```

### The asyncHandler Pattern

Controllers are thin — their only job is to translate HTTP concerns into domain calls:

> **See** [`Backend_Realtime_Workspace/core/utils/api-response.js`](../Backend_Realtime_Workspace/core/utils/api-response.js) — `ApiResponse.success()`, `ApiResponse.error()` — standardised HTTP response envelope

### BaseRepository Pattern

All repositories extend BaseRepository for consistent CRUD with pagination:

> **See** [`Backend_Realtime_Workspace/core/utils/pagination.js`](../Backend_Realtime_Workspace/core/utils/pagination.js) — `parsePagination()`, `buildCursorFilter()`, `encodeCursor()`, `decodeCursor()` — offset + cursor pagination helpers

---

## 3. SOLID Principles in Practice

### Single Responsibility

Each class/module has exactly one reason to change:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Open/Closed

New features via extension, not modification:

> **See** [`Backend_Realtime_Workspace/agent/runtime/streaming.js`](../Backend_Realtime_Workspace/agent/runtime/streaming.js) — `streamResponse()` — SSE token-by-token streaming via Socket.IO

### Dependency Inversion

Services depend on abstractions, not concrete implementations:

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

---

## 4. Error Handling Philosophy

### Only One Error Factory

All errors flow through `AppError` in `core/errors/app-error.js`. Zero raw `new Error()` in application code.

> **See** [`Backend_Realtime_Workspace/core/errors/app-error.js`](../Backend_Realtime_Workspace/core/errors/app-error.js) — `AppError` — typed domain error with HTTP status and error code

### What Not To Do

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

---

## 5. Event-Driven Design

### When to Use Events vs Direct Calls

| Pattern | Use When | Example |
|---------|----------|---------|
| Direct service call | The response is needed immediately | `getProjectById()` |
| Domain event (in-process) | Multiple handlers need to react | `TASK_CREATED` → notify + audit + index |
| Kafka event | Cross-service, must survive restart | AI embedding, analytics aggregation |
| RabbitMQ queue | Exactly-once delivery, retries needed | Email sending, PDF generation |

### Event Contract Design

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 6. Code Style Standards

### Consistent API Responses

> **See** [`Backend_Realtime_Workspace/core/utils/api-response.js`](../Backend_Realtime_Workspace/core/utils/api-response.js) — `ApiResponse.success()`, `ApiResponse.error()` — standardised HTTP response envelope

### Module Exports

> **See** [`Backend_Realtime_Workspace/modules/tasks/task.service.js`](../Backend_Realtime_Workspace/modules/tasks/task.service.js) — `TaskService` — task CRUD, status transitions, assignment logic

### Environment Variable Access

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

---

## 7. Technical Debt Management

### Acceptable Technical Debt

These shortcuts are acceptable early and documented:

| Debt | Acceptable Until | Remediation Path |
|------|----------------|------------------|
| Shared MongoDB collections | 10M+ tenants | Shard by tenantId |
| Single-region deployment | 100k+ MAU in multiple regions | Multi-region K8s + MongoDB Global |
| In-process LangGraph agent | Dedicated AI service needed | Extract agent/ to separate service |
| Modular monolith | Auth/AI hotspot at 1M+ RPS | Extract selective services |
| Manual Terraform apply | Team > 5 engineers | Atlantis / GitHub Actions Terraform |

### Unacceptable Technical Debt

These are never acceptable:
- Missing tenant isolation on any database query
- Catching errors and silently swallowing them
- Direct `process.env` access in business code
- `console.log` in production code (use structured logger)
- Secrets committed to git
- Unvalidated user input reaching MongoDB queries (injection risk)
- Blocking synchronous operations on the event loop (CPU-intensive loops)

---

## 8. Testing Philosophy

### Test Pyramid

```
        /\
       /E2E\          10% — full request lifecycle tests
      /──────\
     /Integr. \       30% — service + repository with real MongoDB (in-memory)
    /────────── \
   /  Unit Tests  \   60% — pure functions, validators, algorithms
  /────────────────\
```

### What to Test

> **See** [`Backend_Realtime_Workspace/core/auth/permission-engine.js`](../Backend_Realtime_Workspace/core/auth/permission-engine.js) — `evaluatePermission()` — RBAC + ABAC + ReBAC (Zanzibar-inspired) evaluation

### Testing AI Components

AI components require special handling because LLM outputs are non-deterministic:

> **See** [`Backend_Realtime_Workspace/agent/runtime/fallback.js`](../Backend_Realtime_Workspace/agent/runtime/fallback.js) — `ModelFallback` — GPT-4o → Claude 3.5 → Cohere fallback chain

Test AI governance (prompt guard) with deterministic injection inputs, not LLM responses.

---

## 9. Documentation Standards

Every non-trivial function or module header must explain:
1. **What it does** (not how — code shows how)
2. **Why it exists** (design decision, tradeoff)
3. **What it does NOT do** (common misunderstandings)

> **See** [`Backend_Realtime_Workspace/modules/auth`](../Backend_Realtime_Workspace/modules/auth) — Auth module — social sign-in, refresh token, logout

This README-as-Code philosophy ensures the architecture.md stays accurate — the code and the docs agree because developers update both.
