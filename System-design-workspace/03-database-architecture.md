# 03 — Database Architecture
# TeamSpot: MongoDB Schema Design, Indexing, Relationships & Polyglot Persistence

---

## 1. Database Strategy: Polyglot Persistence

TeamSpot uses multiple databases, each chosen for what it does best:

| Database | Role | Why |
|----------|------|-----|
| **MongoDB** | Primary transactional store | Flexible schema fits evolving domain models; JSON-native; horizontal sharding; rich aggregation pipeline |
| **Redis** | Cache + presence + sessions + pub/sub | Sub-millisecond reads; TTL-based expiry; pub/sub for Socket.IO; Sorted Sets for leaderboards/feeds |
| **Qdrant** | Vector embeddings (RAG) | Purpose-built ANN vector search with metadata filtering; outperforms Mongo Atlas Vector Search at scale |
| **OpenSearch** | Full-text search + analytics | Inverted index for keyword search; typo tolerance; faceted filtering; aggregations for analytics |
| **Kafka (log)** | Event log / audit stream | Ordered, immutable, replayable event history |

**Golden Rule**: MongoDB is the source of truth. All other stores are derived from MongoDB data via async consumers.

---

## 2. MongoDB Schema Design Philosophy

### Document Embedding vs. Referencing

TeamSpot uses a hybrid approach:

| Pattern | Use When | Example |
|---------|----------|---------|
| **Embed** | Data is always accessed together; small + bounded size; child has no independent lifecycle | Task checklist items, comment reactions, message attachments metadata |
| **Reference (ObjectId)** | Data is accessed independently; unbounded growth; many-to-many relationships | Task → Project, User → Organization, Message → Channel |
| **Hybrid** | Most reads need summary + occasional full detail | Channel stores `{ lastMessage: {text, sender, ts} }` inline, full messages in separate collection |

### Schema Versioning

Every schema includes:
> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

Soft deletes are mandatory. Records are never permanently destroyed on user action — only on legal hold expiry or explicit GDPR erasure requests handled by admin workflows.

---

## 3. Core Schema Definitions

### User Schema

> **See** [`Backend_Realtime_Workspace/modules/auth`](../Backend_Realtime_Workspace/modules/auth) — Auth module — Firebase social, 2FA (TOTP/email/SMS), session management

### Organization Schema

> **See** [`Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js`](../Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js) — `StripeService` — subscription plans, checkout sessions, webhook handlers

### Workspace Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Project Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Task Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Issue Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Ticket Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Channel & Message Schema

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 4. Indexing Strategy

### Index Design Principles

1. **Query-first indexing**: Every index must justify itself with a real query pattern
2. **Compound indexes for multi-field queries**: `{ tenantId, status, dueDate }` — leftmost prefix rule
3. **Partial indexes for sparse data**: `{ deletedAt: 1 }` where `{ deletedAt: { $exists: true } }`
4. **TTL indexes for auto-expiry**: Session tokens, temp invite codes
5. **Text indexes for local search fallback**: Never the primary search path (OpenSearch is)

### Critical Compound Indexes

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 5. Pagination Strategy

TeamSpot uses **cursor-based pagination** for all high-volume endpoints (messages, notifications, audit logs, activity feeds) and **offset pagination** for low-volume management views (user lists, project lists):

> **See** [`Backend_Realtime_Workspace/modules/channels`](../Backend_Realtime_Workspace/modules/channels) — Channels module — message persistence, reactions, thread management

> **See** [`Backend_Realtime_Workspace/core/utils/pagination.js`](../Backend_Realtime_Workspace/core/utils/pagination.js) — `parsePagination()`, `buildCursorFilter()`, `encodeCursor()`, `decodeCursor()` — offset + cursor pagination helpers

---

## 6. Read / Write Optimization

### Write Optimization

> **See** [`Backend_Realtime_Workspace/infrastructure/search/search.service.js`](../Backend_Realtime_Workspace/infrastructure/search/search.service.js) — `SearchService.index()`, `.search()` — OpenSearch integration

### Read Optimization

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 7. Data Archival & Retention

```
Active Data (0-90 days)  → MongoDB primary collections
Archive (90-365 days)    → MongoDB archive collections (same instance, cold tier)
Long-term (365+ days)    → Export to S3-compatible object storage (Cloudflare R2)
GDPR deletion            → Anonymize PII, retain aggregate stats, delete personal data
```

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source
