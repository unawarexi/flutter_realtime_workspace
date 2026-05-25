# 13 — Algorithms & Data Structures
# TeamSpot: Core Algorithms, Complexity Analysis & Engineering Tradeoffs

---

## 1. Overview

TeamSpot uses algorithms and data structures at three levels:
1. **Infrastructure algorithms** — how Redis, Kafka, MongoDB internally work (must understand to use correctly)
2. **Application algorithms** — implemented directly in `core/structures/` and `core/algo/`
3. **Implicit algorithms** — pagination, rate limiting, permission evaluation that use algorithmic thinking

---

## 2. Core Data Structures (core/structures/index.js)

### LRU Cache (Least Recently Used)

**Use**: In-process caching for hot permission lookups, template rendering, frequently accessed workspace configs.

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

**Complexity**: O(1) get and put via Map's hash table + insertion-order iterator  
**Why not Redis?**: In-process LRU avoids network roundtrip for extremely hot data (permission lookup on every request). Used as L1 cache; Redis is L2.

### Priority Queue (Binary Heap)

**Use**: Task scheduling (deadline-aware ordering), notification queuing by priority, AI tool execution ordering.

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

**Complexity**: O(log n) push/pop, O(1) peek  
**Use case**: Sort 10k tasks by (priority DESC, dueDate ASC) for a project view without re-sorting the entire array on each insert.

### Trie (Prefix Tree)

**Use**: Fast prefix search for user mentions (@username autocomplete), channel search, project key autocomplete.

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

**Complexity**: O(L) insert/search where L = string length  
**Why Trie over OpenSearch for autocomplete?**: For workspace-scoped mention autocomplete (< 1000 members), an in-process Trie is sub-millisecond. OpenSearch would add 20-50ms network latency for this micro-interaction.

---

## 3. Pagination Algorithm (Cursor-Based)

**Problem**: Offset pagination (`SKIP n`) is O(n) in MongoDB — it reads and discards the first n documents. At n=10000, this is catastrophically slow.

**Solution**: Cursor pagination using the last document's `_id` as the cursor.

> **See** [`Backend_Realtime_Workspace/core/utils/pagination.js`](../Backend_Realtime_Workspace/core/utils/pagination.js) — `parsePagination()`, `buildCursorFilter()`, `encodeCursor()`, `decodeCursor()` — offset + cursor pagination helpers

**Complexity**: O(log n) with compound index on `(tenantId, sortField, _id)`  
**vs. Offset**: At page 100 (offset=2000), cursor is still O(log n); offset is O(2000).

---

## 4. Rate Limiting: Sliding Window Log Algorithm

> **See** [`Backend_Realtime_Workspace/infrastructure/redis/redis.service.js`](../Backend_Realtime_Workspace/infrastructure/redis/redis.service.js) — `checkRateLimit()` (sliding window, Redis sorted set) + [`Backend_Realtime_Workspace/middlewares/ratelimit.middleware.js`](../Backend_Realtime_Workspace/middlewares/ratelimit.middleware.js) — preset rate limiters (api, auth, chat, upload)

**Why sliding window over fixed window?**: Fixed window allows 2× burst at window boundaries. Sliding window is smooth and prevents gaming the boundary.

**Why sorted set over counter?**: Sorted set allows precise sliding; counter only supports fixed windows. Tradeoff: higher Redis memory (each request is a member).

---

## 5. Permission Evaluation: Zanzibar-Inspired ReBAC

The permission engine evaluates 3 types of checks in order (fail-fast):

> **See** [`Backend_Realtime_Workspace/core/auth/permission-engine.js`](../Backend_Realtime_Workspace/core/auth/permission-engine.js) — `evaluatePermission()` — RBAC + ABAC + ReBAC (Zanzibar-inspired) evaluation

**Caching**: Permission results are cached in the in-process LRU (L1) + Redis (L2) with 30s TTL. Role changes flush the cache immediately.

**Why not pure RBAC?**: Simple RBAC cannot express "user can edit a task because they are a collaborator on the parent project". That requires ReBAC.

---

## 6. Search: Inverted Index (OpenSearch)

OpenSearch (Elasticsearch-compatible) maintains an **inverted index**:

```
Traditional index:  DocumentID → Words
Inverted index:     Word → [DocumentID, DocumentID, ...]

"sprint" → [task:123, task:456, issue:789, channel_msg:101]
"backend" → [task:123, project:55, doc:22]

Query "sprint backend" → intersection → [task:123]
```

**Complexity**: O(1) per term lookup, O(k) for merging k result sets  
**TF-IDF scoring**: Terms rare across documents but frequent in a specific document rank higher. Ensures relevant results rise to top.

**TeamSpot indexing strategy**:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 7. Vector Similarity Search (Qdrant HNSW)

For RAG semantic search, Qdrant uses **HNSW (Hierarchical Navigable Small World)**:

```
Naive approach: compare query vector against ALL stored vectors → O(n·d)
  For 1M documents, 1536-dim embeddings: 1M × 1536 = 1.5B operations → too slow

HNSW approach:
  Build multi-layer graph where nearby vectors are connected
  Search starts at top (coarse layer), descends to fine layer
  Complexity: O(log n · d) average case, configurable recall/speed tradeoff
```

**TeamSpot configuration**:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

**ACL-aware retrieval**: Every semantic search adds `must` filters on `tenantId` + document-level permissions. Even if vectors are close, documents the user cannot access are never returned.

---

## 8. Feed Fanout Algorithm

For channel messages and activity feeds, TeamSpot uses **hybrid fanout**:

```
Fanout-on-write (push model):
  When user A posts message:
    → write to channel messages collection
    → publish to Kafka teamspot.messages topic
    → Kafka consumer pushes via Socket.IO to all channel members online now

Fanout-on-read (pull model):
  For offline users:
    → they fetch messages via REST API on reconnect
    → cursor-based pagination from MongoDB

Hybrid wins because:
  - Active users: sub-100ms delivery via Kafka → Socket.IO
  - Offline users: efficient cursor fetch, no wasted writes to offline queues
  - Large channels (1000+ members): avoids writing 1000 inbox records per message
```

This is the same pattern used by Twitter (fanout-on-write for small followings, fanout-on-read for large followings).

---

## 9. ULID vs UUID for IDs

TeamSpot uses **ULID** (Universally Unique Lexicographically Sortable Identifier) for event IDs and **MongoDB ObjectId** for entity IDs.

```
UUID v4: 550e8400-e29b-41d4-a716-446655440000
  → Random: good uniqueness, poor sortability
  → MongoDB index fragmentation under high insert rate

ObjectId: 507f1f77bcf86cd799439011
  → Timestamp prefix: naturally time-sorted
  → Compact: 12 bytes vs 16 bytes UUID
  → MongoDB native: no conversion needed

ULID:  01ARZ3NDEKTSV4RRFFQ69G5FAV
  → Timestamp prefix + random suffix
  → Monotonically increasing: good for event streaming
  → Used for: eventId, idempotencyKey, requestId
```

---

## 10. Exponential Backoff with Jitter (core/utils/retry.js)

> **See** [`Backend_Realtime_Workspace/core/utils/retry.js`](../Backend_Realtime_Workspace/core/utils/retry.js) — `withRetry()`, `retryWithBackoff()`, `createRetryStrategy()` — exponential backoff with full jitter

**Why jitter matters**: Without jitter, if 1000 requests all fail at t=0 and retry at t=100ms, the server gets another 1000 concurrent requests — making the overload worse. Jitter spreads them across [50ms, 150ms], dramatically reducing thundering herd amplitude.

**Mathematical basis**: AWS paper "Exponential Backoff and Jitter" (2015) showed full jitter reduces server load by up to 90% vs fixed exponential backoff during outage recovery.
