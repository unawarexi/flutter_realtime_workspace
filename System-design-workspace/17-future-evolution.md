# 17 — Future Evolution & Architecture Roadmap
# TeamSpot: Service Extraction, Multi-Region, AI Governance & Long-Term Architecture

---

## 1. Architecture Evolution Model

TeamSpot starts as a **Modular Monolith** and evolves toward **Selective Service Extraction** as load, team size, and operational maturity grow. This is NOT microservices-first — that approach optimizes for org complexity, not technical complexity.

```
Phase 1: Modular Monolith (Now)
  ├── Single deployable unit
  ├── Single MongoDB cluster (multi-tenant row-level)
  ├── In-process event bus
  ├── Kafka/RabbitMQ for async work
  └── K8s horizontal scaling (3–20 pods)

Phase 2: Selective Service Extraction (~100k MAU)
  ├── AI Service extracted (GPU cluster, different scaling profile)
  ├── Media Pipeline extracted (CPU-bound, Cloudinary integration)
  ├── Auth Service extracted (security boundary, separate compliance audit)
  └── Core API remains monolith

Phase 3: Multi-Region + Selective Microservices (~500k MAU)
  ├── Multi-region deployment (US, EU, APAC)
  ├── Real-time Gateway extracted (WebSocket, LiveKit)
  ├── Notification Service extracted (push, email, SMS fan-out)
  ├── Search extracted (OpenSearch cluster, write-through caching)
  └── Core API still relatively cohesive

Phase 4: Full Platform Evolution (~5M+ MAU)
  ├── Full service mesh (Istio)
  ├── Per-tenant database sharding
  ├── Edge compute for real-time presence
  └── Event sourcing for audit trail
```

---

## 2. Service Extraction: Decision Framework

A module should be extracted as a separate service ONLY when ALL of these are true:

| Criterion | Explanation |
|-----------|-------------|
| **Different scaling profile** | It needs 10x more/less resources than the core API |
| **Independent deploy cadence** | It changes independently and frequently |
| **Different failure domain** | Its failure should not bring down the core API |
| **Team ownership** | A dedicated team owns it end-to-end |
| **Maturity** | Its contracts are stable (no weekly breaking changes) |

Extract too early = distributed monolith (worst of both worlds). Extract too late = scaling bottleneck.

---

## 3. Extraction Candidates

### 3.1 AI Service (Priority: High)

**Why extract**: GPU requirements, different language (Python preferred for AI), different auto-scaling (scale to zero when idle), different security boundary (model API keys isolated).

```
AI Service (Python / FastAPI)
├── POST /v1/chat          — LangGraph agent conversation
├── POST /v1/embed         — document embedding (consumed via RabbitMQ)
├── POST /v1/search/vector — Qdrant similarity search
└── POST /v1/classify      — intent classification

Communication: 
  - Sync: gRPC from API pods to AI service (low latency)
  - Async: RabbitMQ for background embedding (fire-and-forget)
  
Scaling: Karpenter GPU node pool, scale to zero on weekends
```

Migration path:
1. Create `ai.service.js` adapter in current monolith
2. Behind feature flag: route AI calls to new service
3. Validate parity in staging
4. Flip flag in production (0 downtime migration)
5. Remove old agent code from monolith

### 3.2 Real-Time Gateway (Priority: Medium)

**Why extract**: WebSocket connections are stateful and long-lived. They have fundamentally different scaling characteristics than REST (fewer pods, more connections per pod). Kubernetes Horizontal Pod Autoscaler doesn't scale well based on connection count by default.

```
WebSocket Gateway
├── Manages Socket.IO connections
├── Redis adapter for cross-pod pub/sub (already implemented)
├── LiveKit orchestration
└── Presence management

Communication:
  - Events from core API → Redis pub/sub → WebSocket Gateway → client
  - Core API never holds WebSocket connections
```

### 3.3 Notification Service (Priority: Medium)

**Why extract**: Fan-out problem — one event can generate 10,000+ notifications. This puts enormous pressure on RabbitMQ workers in the monolith. A dedicated service with proper queue management, deduplication, and delivery tracking is cleaner.

```
Notification Service
├── Email (SMTP/SendGrid) — transactional, marketing
├── Push (FCM/APNs) — via Firebase Admin SDK
├── SMS — Twilio integration
├── In-app — WebSocket delivery via Real-Time Gateway
└── Webhook — outbound event delivery to integrations
```

---

## 4. Multi-Region Architecture (Phase 3)

```
                        ┌─────────────────────────────────────┐
                        │         Cloudflare Global           │
                        │   (GeoDNS, WAF, DDoS protection)   │
                        └──────────┬────────────┬────────────┘
                                   │            │
               ┌───────────────────▼──┐  ┌──────▼───────────────┐
               │    US-EAST Region    │  │   EU-WEST Region     │
               │  ──────────────────  │  │  ─────────────────   │
               │  API Cluster (K8s)   │  │  API Cluster (K8s)  │
               │  MongoDB US Primary  │  │  MongoDB EU Primary │
               │  Redis (regional)    │  │  Redis (regional)   │
               └──────────┬───────────┘  └──────────┬──────────┘
                          │                          │
                          └────────────┬─────────────┘
                                       │
                          ┌────────────▼────────────┐
                          │  MongoDB Global Cluster  │
                          │  (Atlas Global Writes)  │
                          │  Zone-based sharding    │
                          └─────────────────────────┘
```

### Data Residency Strategy

For enterprise customers in EU/APAC with data residency requirements:
- **Workspace data**: stored only in customer's chosen region
- **Global data**: user profiles, billing stored globally
- **Enforcement**: `tenantId` includes region prefix → routing middleware directs to correct cluster

---

## 5. Per-Tenant Database Evolution

Current (Phase 1-2): Shared database, shared collections, row-level isolation via `tenantId`

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

Phase 3 (Enterprise tier): **Database-per-tenant** for large customers
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

Migration path: copy tenant data to dedicated cluster, update routing table, verify, deprecate shared records.

---

## 6. AI Governance Evolution

### Current State (Phase 1)
- Rule-based PromptGuard (regex pattern matching)
- Static allowlist of tool names
- Per-user rate limiting on AI endpoint
- Audit log of all AI requests

### Near-Term (Phase 2)
- LLM-based prompt injection classifier (fine-tuned on attack corpus)
- Content moderation for AI responses (perspective API or custom classifier)
- Tenant-level AI usage quotas (not just user-level)
- AI response caching for identical queries (semantic dedup)

### Long-Term (Phase 3)
- **On-premise model option**: enterprise customers can bring their own LLM (Ollama, Azure OpenAI)
- **AI audit compliance**: GDPR-compliant explanation of every AI decision
- **Federated learning**: model improvement from usage without seeing raw data
- **Agent authorization**: each tool call requires explicit permission scope (OAuth-like)

---

## 7. Search Evolution

**Phase 1 (Now)**: OpenSearch full-text search across workspace entities

**Phase 2**: Hybrid search — combine keyword (BM25) + semantic (Qdrant vector) in single API response
```
user query → tokenize → [BM25 score, vector similarity score] → RRF merge → ranked results
```

**Phase 3**: Personalized search ranking
```
search results re-ranked by:
  - user's recent activity (recently viewed tasks/docs scored higher)
  - user's team context (teammates' content scored higher)
  - semantic relevance to current workspace context
```

---

## 8. Long-Term Technology Decisions

| Decision | Current | Future Trigger | Migration Path |
|----------|---------|----------------|----------------|
| **JavaScript** | Node.js 20 ESM | Performance-critical services | Rust/Go for media pipeline (not full rewrite) |
| **MongoDB** | Mongoose 8.15 ODM | Complex relational queries at scale | Keep Mongo; add PostgreSQL for analytics |
| **Monolith deploy** | 3–20 K8s pods | Team > 20 engineers | Selective extraction (see §3) |
| **JWT auth** | In-house JWT | Enterprise SSO demand | SAML 2.0 / OIDC federation layer |
| **RBAC model** | RBAC+ABAC+ReBAC | Complex org hierarchies | SpiceDB or Ory Keto (dedicated authz) |
| **Kafka topics** | Manual topic management | 50+ topics | Schema Registry + Confluent governance |

---

## 9. When to Stop Evolving

Not every architecture evolves continuously. These stability signals indicate you've reached appropriate complexity:

- **Good signal**: Deploying twice daily without incidents
- **Good signal**: P95 latency < 100ms at current load
- **Good signal**: Any engineer can onboard in 2 days
- **Warning signal**: 3+ incidents/month from infrastructure complexity
- **Warning signal**: Deploying one service requires changing 4 others
- **Stop signal**: Engineering org spends > 30% time on infra (not features)

When these warning signals appear, evaluate whether adding architecture helps or hurts. More architecture is not always better architecture.
