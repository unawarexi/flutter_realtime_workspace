# 02 — Product Architecture & Domain Design
# TeamSpot: Bounded Contexts, Module Boundaries & Data Ownership

---

## 1. Architectural Pattern: Modular Monolith

TeamSpot is structured as a **modular monolith** — a single deployable process with strictly enforced internal domain boundaries. This is the same pattern used by Shopify, Basecamp, and early Linear before they selectively extracted services.

### Why Not Microservices From Day One?

Microservices solve organizational scaling problems (teams that cannot coordinate), not technical scaling problems (servers that cannot handle load). Premature decomposition creates:

- Distributed transaction hell (no ACID across service boundaries)
- Network latency on every inter-domain call
- Operational overhead that kills small teams
- Premature API contracts that become prisons

The correct evolution path is:
```
Modular Monolith → Event-Driven Internal Bus → Selective Service Extraction
```

TeamSpot is at stage 1, with stage 2 implemented via Kafka/RabbitMQ, making stage 3 non-disruptive.

---

## 2. Domain Map — Bounded Contexts

Each module represents a bounded context with its own:
- Data models (Mongoose schemas)
- Service layer (business logic)
- Repository layer (data access)
- Controller layer (HTTP interface)
- Route definitions

### Core Identity & Access Domains

```
┌─────────────────────────────────────────────────────────────────┐
│  IDENTITY FABRIC (cross-cutting)                                 │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────────────┐ │
│  │   Auth   │  │ Organizations│  │        Identity            │ │
│  │ (Firebase│  │ (multi-tenant│  │  (RBAC+ABAC+ReBAC roles,  │ │
│  │  + 2FA)  │  │  root entity)│  │   permissions, policies)  │ │
│  └──────────┘  └──────────────┘  └────────────────────────────┘ │
│  ┌──────────┐  ┌──────────────┐                                  │
│  │  Users   │  │  Workspaces  │                                  │
│  │ profiles │  │  (scoped to  │                                  │
│  │ referrals│  │     orgs)    │                                  │
│  └──────────┘  └──────────────┘                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Work Management Domains

```
┌─────────────────────────────────────────────────────────────────┐
│  WORK MANAGEMENT                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Projects │  │  Tasks   │  │  Issues  │  │   Tickets    │   │
│  │ timeline │  │ comments │  │ linked   │  │  SLA/queues  │   │
│  │ Gantt    │  │ checklist│  │ to proj  │  │  (support)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │  Teams   │  │Schedules │  │Workflows │                       │
│  │ members  │  │ calendar │  │ auto-    │                       │
│  │ analytics│  │ RSVP     │  │ mation   │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### Communication Domains

```
┌─────────────────────────────────────────────────────────────────┐
│  COMMUNICATION                                                    │
│  ┌──────────┐  ┌──────────────────┐  ┌──────────────┐          │
│  │ Channels │  │  Communication   │  │   Meetings   │          │
│  │ (Slack-  │  │  (LiveKit video, │  │  (scheduled, │          │
│  │  like)   │  │  VoIP, DMs)      │  │   RSVP)      │          │
│  └──────────┘  └──────────────────┘  └──────────────┘          │
│  ┌──────────┐  ┌──────────────┐                                  │
│  │Notifica- │  │  Whiteboards │                                  │
│  │  tions   │  │  (real-time  │                                  │
│  │FCM+in-app│  │  canvas)     │                                  │
│  └──────────┘  └──────────────┘                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Knowledge & Intelligence Domains

```
┌─────────────────────────────────────────────────────────────────┐
│  KNOWLEDGE & AI                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │Documents │  │  Search  │  │    AI    │  │  Templates   │   │
│  │RAG index │  │(OpenSrch)│  │ LangGraph│  │ (email/PDF/  │   │
│  │PDF/DOCX  │  │full-text │  │ + RAG +  │  │  notif tmpl) │   │
│  └──────────┘  └──────────┘  │   MCP    │  └──────────────┘   │
│                               └──────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### Platform & Operations Domains

```
┌─────────────────────────────────────────────────────────────────┐
│  PLATFORM & OPS                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Admin   │  │ Billing  │  │Integra-  │  │   Analytics  │   │
│  │impersona-│  │ (Stripe) │  │  tions   │  │ (dashboards, │   │
│  │tion/SLA  │  │ invoices │  │GH/Slack  │  │   reports)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Audit   │  │ Storage  │  │ Feedback │  │    Legal     │   │
│  │immutable │  │Cloudinary│  │ bug rpts │  │ ToS/Privacy  │   │
│  │  logs    │  │ + media  │  │          │  │  (no-auth)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Multi-Tenancy Architecture

Every entity in TeamSpot carries a multi-tenancy context:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Isolation Strategy: Shared Database, Shared Collections, Row-Level Isolation

TeamSpot uses **shared collections with tenant-scoped indexes**. This is the correct choice at this scale:

| Strategy | Pros | Cons | When |
|----------|------|------|------|
| Database-per-tenant | Perfect isolation | Ops nightmare at 10k+ orgs | Regulated (HIPAA) |
| Schema-per-tenant | Good isolation | Complex migrations | Mid-scale regulated |
| **Row-level isolation** | Simple ops, shared infra | Requires discipline | **TeamSpot ← here** |

Every MongoDB query **must** include `{ tenantId }` as a filter. The `tenantMiddleware` injects `req.tenant` on every request. Failure to include it is a security bug, not a logic bug.

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Tenant Resolution Flow

```
Request Header: X-Tenant-ID or JWT claim or subdomain
       ↓
tenantMiddleware (global Express middleware)
       ↓
Resolves org from MongoDB (cached in Redis 10min TTL)
       ↓
Attaches req.tenant = { id, plan, features, quotas }
       ↓
firebaseAuthMiddleware verifies token + cross-checks org membership
       ↓
permissionMiddleware checks RBAC/ABAC for resource action
```

---

## 4. Module Structure (Standard Pattern)

Every module follows this layered structure:

```
modules/{domain}/
├── {domain}.routes.js      # Express Router — HTTP endpoints, middleware chain
├── {domain}.controller.js  # Thin: parse req → call service → format response
├── {domain}.service.js     # Business logic: orchestrate repos + events + external calls
├── {domain}.repository.js  # Data access: extends BaseRepository, Mongoose queries
├── {domain}.validator.js   # express-validator rules + zod schemas
├── models/
│   └── {domain}.model.js   # Mongoose schema + indexes + statics
└── {domain}.test.js        # Vitest unit/integration tests
```

### Dependency Rules
- Routes import controllers only
- Controllers import services only
- Services import repositories + infrastructure clients + core utilities
- Repositories import models only
- Models have no dependencies on other layers

This is Clean Architecture / Hexagonal Architecture applied pragmatically to Node.js.

---

## 5. Cross-Cutting Concerns (Core Layer)

The `core/` directory contains concerns that every module uses but no module owns:

### Authentication & Authorization

```
core/auth/
├── firebase-auth.middleware.js  # Primary auth — verify Firebase ID token
│                                # Attaches req.user = { uid, email, displayName }
├── permission-engine.js         # RBAC + ABAC + ReBAC (Zanzibar-inspired)
│                                # Permission types:
│                                #   RBAC: role has permission by default
│                                #   ABAC: attribute match (dept, team, project)
│                                #   ReBAC: "can edit because collaborator on project"
├── permission.middleware.js     # requirePermission('create', 'task') factory
└── tenant.middleware.js         # Resolve + attach tenantId to every request
```

### Error Handling

> **See** [`Backend_Realtime_Workspace/core/errors/app-error.js`](../Backend_Realtime_Workspace/core/errors/app-error.js) — `AppError` — typed domain error with HTTP status and error code

### Event Bus (Internal Domain Events)

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 6. Data Ownership Map

| Data | Source of Truth | Cache | Search Index | Vector Index |
|------|----------------|-------|--------------|--------------|
| Users, orgs, workspaces | MongoDB | Redis (5-10min) | - | - |
| Projects, tasks, issues | MongoDB | Redis (30-60s) | OpenSearch | - |
| Channels, messages | MongoDB | Redis (presence) | OpenSearch | - |
| Meetings, schedules | MongoDB | Redis (60s) | - | - |
| Documents | MongoDB + Cloudinary | - | OpenSearch | Qdrant (embeddings) |
| AI conversations | MongoDB | Redis (session) | - | - |
| Audit logs | MongoDB (append-only) | - | OpenSearch | - |
| Presence/online status | Redis HSET only | - | - | - |
| Session tokens | Redis TTL | - | - | - |
| Billing state | Stripe (canonical) + MongoDB (cache) | Redis (5min) | - | - |

**Critical Rule**: Redis is **never** the source of truth. Redis data can always be regenerated from MongoDB. If Redis fails, the application degrades gracefully to MongoDB reads.

---

## 7. Service Communication Patterns

### Synchronous (HTTP request path)
Used for: user-facing API calls that need an immediate response.
```
Controller → Service → Repository → MongoDB
                    ↘ Redis (cache hit)
```

### Asynchronous (Event-driven)
Used for: work that doesn't need to complete before HTTP response.
```
Service → Kafka topic → Kafka Consumer → Background processing
        → RabbitMQ queue → Worker → Email / FCM / AI embedding
        → DomainEventBus → In-process handlers (same request lifecycle)
```

### Real-time (WebSocket)
Used for: live UI updates pushed from server to client.
```
Kafka Consumer / Service → Socket.IO → Client room
                         ↗ Redis pub/sub (multi-node fanout)
```

---

## 8. Module Dependency Graph (High-Level)

```
auth ←─── users ←──── organizations ←─── workspaces
              ↑              ↑                  ↑
           identity       teams             projects
                                               ↑ ↑ ↑
                                           tasks issues tickets
                                               ↓
                                    communication ← channels
                                               ↓
                                    notifications ← meetings
                                               ↓
                                     ai ← documents ← storage
                                      ↓
                                  analytics ← audit ← admin
                                      ↓
                              billing ← integrations ← workflows
```

Arrows indicate "depends on" at the service level. Circular dependencies are forbidden — use the event bus to break cycles.

---

## 9. Invite-Only Onboarding Flow

TeamSpot uses an invite-gated onboarding system. New employees cannot join an organization workspace without an explicit invitation:

```
Admin/Manager generates invite link
         │
         ▼
POST /organizations/:id/invite
  → Creates InviteToken { code, orgId, workspaceId, role, expiresAt, uses }
  → Sends email via mailer.service.js (Handlebars template)
         │
         ▼
New User clicks invite link in Flutter app (deep link)
         │
         ▼
Firebase Social Auth (Google / GitHub OAuth)
         │
         ▼
POST /auth/social  { idToken, inviteCode }
  → Verifies Firebase token
  → Validates invite code: not expired, not exceeded max uses
  → Creates User in MongoDB with role from invite
  → Adds User to Organization + Workspace
  → Marks invite as used (decrements uses counter)
  → Returns backend JWT
```

**Security Properties**:
- Invite codes expire after 7 days by default (`WorkspaceConfig.INVITE_EXPIRY_DAYS`)
- Each code can be single-use or multi-use (admin configures)
- Used invite codes remain in the database for audit trail
- Backend JWT is separate from Firebase token — Firebase token is only used for authentication, never for authorization
