# 18 — Interview Preparation: 100 Advanced Questions
# TeamSpot System Design: Questions, Ideal Answers & Principal Engineer Perspectives

---

## How to Use This Document

For each question you'll find:
- **Ideal answer**: What a strong senior/staff engineer would say
- **Common bad answer**: What trips up most candidates
- **What the interviewer evaluates**: The hidden test beneath the question
- **Senior perspective**: What a senior engineer adds
- **Principal perspective**: What a principal/staff architect adds

---

## Section A: Distributed Systems (Q1–20)

---

**Q1: How does TeamSpot maintain consistency when a task update happens concurrently from web and mobile?**

**Ideal answer**: We use optimistic concurrency control. Every document has a `version` field. On update: `findOneAndUpdate({ _id, version }, { $set: update, $inc: { version: 1 } })`. If the query matches 0 documents, the version was stale — client gets 409 Conflict and must re-fetch.

**Common bad answer**: "We use transactions" — MongoDB multi-doc transactions are expensive and don't solve the fundamental concurrency problem without version control.

**What interviewer evaluates**: Do you understand the difference between isolation (transactions) and conflict detection (OCC)? Do you know when to use each?

**Senior perspective**: Also mention last-write-wins as an alternative for low-stakes fields (e.g., task status) where conflicts are rare and the user intent is clear.

**Principal perspective**: Evaluate which fields warrant OCC (high-conflict, user-visible) vs eventual consistency (analytics counters, view counts) vs CRDTs (collaborative text editing). Don't apply the same consistency model to everything.

---

**Q2: Explain how Socket.IO messages are delivered to users connected to different pods.**

**Ideal answer**: Socket.IO uses the `@socket.io/redis-adapter` package. When user A (on pod 1) sends a message, pod 1 publishes to a Redis pub/sub channel. All pods are subscribed. The other pods forward the event to their connected clients. The Redis channel key is the Socket.IO room ID — typically `channelId` or `meetingId`.

**Common bad answer**: "All users connect to the same pod" — this doesn't work with horizontal scaling.

**What interviewer evaluates**: Do you know what a stateful service is and how to make it stateless-compatible?

**Senior perspective**: Redis pub/sub is eventually consistent. Messages can be lost if a subscriber is temporarily disconnected. For guaranteed delivery, supplement with Kafka consumer that re-delivers missed events on reconnect.

**Principal perspective**: At very large scale (millions of connections), Redis pub/sub becomes a bottleneck. Evolution: partition by tenantId (each tenant's events on dedicated Redis channel), then NATS JetStream, then custom pub/sub mesh.

---

**Q3: What is the CAP theorem and how does MongoDB apply to it?**

**Ideal answer**: CAP: Consistency, Availability, Partition Tolerance — pick two during a network partition. MongoDB with a replica set defaults to CP: it sacrifices availability (primary elections take 10–30s) to maintain consistency. With `readPreference: 'secondary'`, you get AP for reads but with potentially stale data.

**Common bad answer**: "MongoDB is ACID so it's consistent" — ACID and CAP are different concepts.

**What interviewer evaluates**: Can you apply theoretical computer science to real architectural decisions?

**Senior perspective**: PACELC is more precise than CAP for modern systems. It asks: when there's no partition, what's the tradeoff between latency and consistency? MongoDB primaries sacrifice some latency to guarantee consistency on write (journaling).

**Principal perspective**: Most applications never experience network partitions. Optimizing for partition handling before you have the traffic is premature. Focus on performance under normal operation; design for graceful degradation during partitions.

---

**Q4: How do you prevent duplicate event processing in Kafka consumers?**

**Ideal answer**: Three techniques, often combined: (1) Idempotency keys — producer includes a `messageId` (ULID), consumer stores processed IDs in Redis with `SET msgId:${id} 1 NX EX 86400`. (2) Transactional outbox — store event in MongoDB in same transaction as state change; separate process reads and publishes, guaranteeing at-least-once. (3) Consumer group offsets — commit offsets only after successful processing to prevent skips.

**Common bad answer**: "Kafka guarantees exactly-once" — it does with Kafka Streams + transactional producers, but only within Kafka. Once you write to MongoDB, external exactly-once requires idempotency on the application side.

**What interviewer evaluates**: Understanding of at-least-once vs exactly-once delivery and the effort required for each.

**Senior perspective**: Exactly-once processing is expensive. For TeamSpot's analytics counter use case, duplicate counting is acceptable (minor overcounting). For billing events, exactly-once is worth the overhead.

**Principal perspective**: Design the system so that most operations are naturally idempotent. `SET counter = counter + 1` is not idempotent. `SET status = 'completed' WHERE status != 'completed'` is. This architectural choice is more valuable than any deduplication mechanism.

---

**Q5: How would you design a rate limiter that works across multiple API pods?**

**Ideal answer**: Token bucket algorithm with Redis as the shared counter. Key: `ratelimit:${userId}:${windowStart}`. Each request does `INCR key; EXPIRE key 60`. If count > limit, reject with 429. Window start is `Math.floor(Date.now() / 60000)`. This gives 60-second fixed windows.

For sliding windows (more accurate): use a Redis sorted set per user with request timestamps. `ZADD` for each request, `ZRANGEBYSCORE` to count within window, `ZREMRANGEBYSCORE` to prune old entries. More expensive but no boundary spikes.

**Common bad answer**: "Use in-memory rate limiting per pod" — each pod tracks its own counter, so a user can make N * numPods requests.

**What interviewer evaluates**: Distributed state management + Redis data structures knowledge.

**Senior perspective**: Redis round-trip adds 1–2ms latency to every request. For very high QPS endpoints, use a Redis Lua script to combine INCR + EXPIRE in a single round-trip (atomic, no race condition).

**Principal perspective**: Rate limiting at the API level is the last line of defense. The first lines are: Cloudflare WAF (request rate), Nginx (connection rate), and API key scoping (limiting which endpoints each key can call). Defense in depth prevents any single layer from being overwhelmed.

---

**Q6: How does cursor-based pagination work and why is it better than OFFSET?**

**Ideal answer**: With offset pagination (`SKIP n`), MongoDB scans and discards the first n documents on every page. For page 100 with 20 per page, MongoDB scans 2,000 documents and returns 20. Performance is O(n) where n = total items skipped.

Cursor pagination uses the last seen document's unique field (typically `_id` or a sort key) as an anchor. `{ _id: { $gt: lastSeenId } }` MongoDB immediately jumps to that position in the B-tree index — O(log n) lookup. Performance is constant regardless of page number.

> **See** [`Backend_Realtime_Workspace/core/utils/pagination.js`](../Backend_Realtime_Workspace/core/utils/pagination.js) — `parsePagination()`, `buildCursorFilter()`, `encodeCursor()`, `decodeCursor()` — offset + cursor pagination helpers

**Common bad answer**: "Just use page number and limit" — this is OFFSET pagination, doesn't scale.

**What interviewer evaluates**: Index knowledge, query performance reasoning, real-world API design.

**Senior perspective**: Cursor pagination prevents "page drift" — if items are inserted/deleted while paginating, offset pages skip or duplicate items. Cursors are stable anchors.

**Principal perspective**: For feeds (sorted by score, not _id), cursors require composite cursor encoding: `{score, _id}` to handle ties. For real-time feeds, consider event sourcing or append-only log patterns instead of paginating mutable collections.

---

**Q7: Explain the difference between Kafka and RabbitMQ and when you'd use each.**

**Ideal answer**:
| | Kafka | RabbitMQ |
|--|-------|----------|
| Model | Log-based streaming | Message broker queue |
| Retention | Days/weeks (even after consume) | Deleted after ack |
| Delivery | Pull (consumer controls rate) | Push to consumer |
| Ordering | Guaranteed per partition | Not guaranteed across queues |
| Throughput | Millions/sec | Tens of thousands/sec |
| Use case | Event streaming, audit, analytics | Task queues, RPC, workflows |

TeamSpot uses Kafka for: audit logs, analytics events, AI indexing triggers (consumers can replay from any offset).
TeamSpot uses RabbitMQ for: email delivery, PDF generation, AI embedding (transient tasks that execute once, no replay needed).

**Common bad answer**: "Kafka is better, use it for everything" — RabbitMQ's push model and per-message TTL are better for task queues.

**What interviewer evaluates**: System selection reasoning, not memorized feature lists.

---

**Q8: How would you detect and prevent a slow MongoDB query from cascading into a full outage?**

**Ideal answer**: Four-layer approach:
1. **Schema indexes**: compound indexes on all query patterns, `explain()` in CI to catch missing indexes
2. **Query timeout**: Mongoose `maxTimeMS: 5000` on all queries — slow query aborts before tying up connection pool
3. **Circuit breaker**: If DB error rate > 10% in 10 seconds, open circuit — return cached data or 503 immediately instead of hammering DB
4. **Connection pool limit**: Mongoose `maxPoolSize: 50` prevents connection pool exhaustion

**What interviewer evaluates**: Defense-in-depth thinking — no single protection point, layered mitigations.

---

**Q9: What is a distributed transaction and why does TeamSpot avoid them?**

**Ideal answer**: Distributed transactions span multiple databases/services and require a coordinator (2-phase commit). Problems: if coordinator fails mid-transaction, all participants are locked. Network delays increase latency. MongoDB multi-document transactions are expensive and don't span across services.

TeamSpot avoids them by designing for eventual consistency: emit domain events, use idempotent handlers, use the Saga pattern for multi-step operations (each step publishes compensation events on failure).

Example: `CreateWorkspace` saga: create workspace → create default channel → invite owner → set up billing. Each step publishes success/failure. If billing fails, compensation events delete the workspace and channel.

**What interviewer evaluates**: Understanding of distributed systems tradeoffs, not just "use transactions for everything".

---

**Q10: How does TeamSpot handle clock skew in distributed systems?**

**Ideal answer**: TeamSpot uses monotonic IDs (ULIDs) instead of relying on wall clock for ordering. ULIDs embed a timestamp component but sort correctly even with minor clock drift because they include random bits.

For audit logs requiring precise timestamps: use server-side timestamps only (never client-supplied), set MongoDB `{ timestamps: true }` option (server-generated via `new Date()`).

For rate limiting windows: use Redis server time (`TIME` command) instead of application server time to avoid clock skew across pods.

**What interviewer evaluates**: Awareness of distributed system timing problems.

---

## Section B: Database Design (Q11–25)

---

**Q11: How is multi-tenancy implemented in TeamSpot's MongoDB schema?**

**Ideal answer**: Shared database, shared collections, row-level isolation. Every document across all collections has a `tenantId` field. BaseRepository enforces tenant scoping on every query — it's impossible to accidentally query across tenant boundaries.

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

**Common bad answer**: "Create a separate database per tenant" — operationally expensive at scale, hard to manage 10,000+ databases.

**What interviewer evaluates**: Multi-tenancy patterns, index design, operational tradeoffs.

**Principal perspective**: The shared collection model works until around 10M tenants or until enterprise customers demand data isolation guarantees. Plan the migration path early (see 17-future-evolution.md §5).

---

**Q12: What indexes would you put on the tasks collection for typical query patterns?**

**Ideal answer**: Based on TeamSpot's query patterns:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

Avoid: wildcard indexes (expensive writes), too many indexes (write amplification — each index is updated on every write).

**What interviewer evaluates**: Index selection reasoning — not just "add an index on everything".

---

**Q13: When would you use MongoDB aggregation pipeline vs multiple separate queries?**

**Ideal answer**: Use aggregation pipeline when:
- Joining data from multiple collections (`$lookup`) to avoid N+1 queries
- Performing server-side computation (group by, sum, count)
- Need atomic snapshot of aggregated data

Use separate queries when:
- The joined collection is large (MongoDB `$lookup` is not like SQL JOIN — it scans)
- Aggregation result would be too large for a single document (16MB BSON limit)
- Query results will be cached separately

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

**Q14: Explain the difference between indexing strategies for read-heavy vs write-heavy workloads.**

**Ideal answer**:
- **Read-heavy** (TeamSpot dashboards, project views): Prioritize query-serving indexes. Add composite indexes for common query patterns. The write amplification cost (each index updated per write) is acceptable.
- **Write-heavy** (audit logs, analytics events, real-time presence): Minimize indexes. Write amplification multiplies across millions of events. Use capped collections or append-only design. Move analytics aggregations to Kafka consumer.

TeamSpot audit logs intentionally have only two indexes: `{ tenantId, createdAt }` and `{ tenantId, userId, createdAt }` — enough to query an audit trail without crippling ingest throughput.

---

**Q15: How would you implement full-text search with relevance ranking in TeamSpot?**

**Ideal answer**: Two-layer approach:
1. **OpenSearch (primary)**: BM25 ranking for structured entities (tasks, projects, channels). Indexed fields: title, description, tags. Query: `multi_match` across fields with `fuzziness: AUTO` for typo tolerance.

2. **Qdrant (semantic)**: Embedding-based search for natural language queries. "tasks about Q4 planning" → embed query → nearest neighbor search in vector space.

Hybrid: run both in parallel, merge with Reciprocal Rank Fusion (RRF): `score = Σ 1 / (k + rank_i)` where k=60 is a constant.

This gives precision (BM25 for exact matches) + recall (semantic for conceptual matches).

---

## Section C: Real-Time Infrastructure (Q16–30)

---

**Q16: How does TeamSpot's presence system work at scale?**

**Ideal answer**: Redis HSET stores presence data:
```
Key: presence:{tenantId}:{userId}
Fields: status, lastSeen, currentRoomId
TTL: 5 minutes (renewed on heartbeat)
```

WebSocket clients send heartbeat every 30s. Server renews TTL. Client disconnect → TTL expires → presence removed. Redis keyspace notifications fire an event when keys expire — subscriber broadcasts `user.offline` event.

Fetching team presence: `HGETALL presence:{tenantId}:*` — one Redis command for all users in a workspace.

Scale challenge: at 100k concurrent users in one tenant, 100k HSET entries. Still fast (Redis can handle millions of HSET). The problem is fan-out: broadcasting presence changes to all 100k users. Solve with sparse updates (only broadcast to users who are watching the relevant view).

---

**Q17: Explain how a message in a team channel reaches all recipients.**

**Ideal answer**:
```
1. Client sends POST /channels/{id}/messages (HTTP)
2. MessageService.create():
   a. Persist to MongoDB
   b. eventBus.emit('message.created', { message, channelId, tenantId })
3. NotificationHandler:
   a. Fetches channel members from cache (Hive on mobile, Redis on server)
   b. Publishes to Redis pub/sub: channel:${channelId}
4. All Socket.IO pods subscribed via Redis adapter receive event
5. Each pod delivers to connected clients in that channel room
6. For offline users: push notification via FCM/APNs via RabbitMQ queue
```

**What interviewer evaluates**: End-to-end message flow, understanding of real-time architecture, thinking about offline case.

---

**Q18: What happens to WebSocket connections during a pod restart (rolling update)?**

**Ideal answer**: K8s rolling update terminates old pods while new ones start. Connected WebSocket clients will be disconnected. TeamSpot handles this with:
1. **Graceful shutdown**: SIGTERM triggers `server.close()` — no new connections accepted, existing connections given 30s to finish
2. **Client reconnection**: Socket.IO client has `reconnection: true, reconnectionAttempts: 5, reconnectionDelay: 1000`
3. **State recovery**: On reconnect, client re-subscribes to rooms and requests missed events since last disconnect timestamp
4. **Sticky sessions disabled**: Since we use Redis adapter, reconnecting to ANY pod is fine

**What interviewer evaluates**: Understanding of stateful vs stateless WebSocket servers, graceful degradation.

---

**Q19: How does LiveKit integrate with the TeamSpot backend?**

**Ideal answer**: LiveKit is a WebRTC SFU (Selective Forwarding Unit). TeamSpot backend uses the LiveKit server SDK to:
1. Create rooms: `livekit.createRoom({ name: meetingId, maxParticipants: 100 })`
2. Generate access tokens: `AccessToken` with room `canPublish`, `canSubscribe` grants
3. Update metadata: participant name, role, tenant context

Clients use the LiveKit Flutter SDK to connect directly to LiveKit server (NOT via TeamSpot backend). TeamSpot backend only provides the room token and metadata — it never handles audio/video data.

LiveKit WebHook → TeamSpot backend: room events (participant joined/left, recording started) are delivered via webhook. Backend updates meeting state in MongoDB and emits Socket.IO events to clients.

---

**Q20: How would you handle 10,000 concurrent video calls?**

**Ideal answer**: A single LiveKit SFU handles ~1,000 concurrent rooms. For 10,000 rooms: LiveKit Cloud (managed) auto-scales SFU capacity, or deploy LiveKit cluster with geo-routing.

On TeamSpot backend side: the bottleneck shifts to webhook processing (10,000 events/second during peak). Architecture: LiveKit webhook → Kafka topic → consumer group (10 partitions × 5 workers = 50 concurrent processors).

Meeting token generation is stateless and horizontally scalable (no shared state needed).

**What interviewer evaluates**: Separation of concerns (backend vs SFU), bottleneck identification, horizontal scaling reasoning.

---

## Section D: AI System Design (Q21–35)

---

**Q21: How does the TeamSpot AI agent prevent prompt injection?**

**Ideal answer**: Three-layer defense:
1. **Pre-processing (PromptGuard)**: Regex patterns block known injection phrases (`ignore previous instructions`, `jailbreak`, `DAN mode`)
2. **System prompt isolation**: User input is always in the `human` message role, never concatenated into the system prompt. The system prompt is hardcoded, not user-modifiable.
3. **Tool authorization**: Each AI tool call is validated against the user's permissions. Even if an attacker crafts a prompt to call `search_all_users`, the tool implementation checks ACL before returning data.

**What interviewer evaluates**: Security thinking applied to AI, not just feature-level AI knowledge.

**Principal perspective**: The most dangerous injection bypasses regex and convinces the LLM to exfiltrate data through legitimate-looking tool calls. Tool result logging + anomaly detection (unusually large result sets, queries outside user's tenant) is the final backstop.

---

**Q22: Explain the RAG (Retrieval-Augmented Generation) pipeline in TeamSpot.**

**Ideal answer**:
```
Indexing pipeline (async, triggered by document creation/update):
  1. Document created → Kafka topic 'document.indexed'
  2. RabbitMQ embedding worker picks up task
  3. Worker chunks document (512-token chunks with 50-token overlap)
  4. Each chunk embedded via OpenAI text-embedding-3-small
  5. Vector + metadata (tenantId, documentId, chunkIndex) stored in Qdrant

Query pipeline (synchronous, real-time):
  1. User query → embed with same model → 1536-dim vector
  2. Qdrant HNSW search: top-K=10 similar chunks, filter by tenantId
  3. Re-rank chunks by relevance (cross-encoder)
  4. Top 5 chunks inserted into LLM context as retrieved context
  5. LLM generates answer grounded in retrieved context
  6. Answer + source citations returned to client
```

**What interviewer evaluates**: Practical RAG implementation knowledge, chunking strategy, tenant isolation in vector search.

---

**Q23: How do you prevent the AI from accessing data from other tenants?**

**Ideal answer**: Qdrant vector search always includes a mandatory filter:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

This filter is applied in Qdrant before results are returned to the application. It cannot be bypassed by the LLM. Additionally, tool implementations verify the calling user has read access to each retrieved document.

---

**Q24: What happens when the primary LLM (OpenRouter) is unavailable?**

**Ideal answer**: ModelFallback chain in `agent/runtime/fallback.js`:
> **See** [`Backend_Realtime_Workspace/agent/runtime/fallback.js`](../Backend_Realtime_Workspace/agent/runtime/fallback.js) — `ModelFallback` — GPT-4o → Claude 3.5 → Cohere fallback chain

Each provider is tried in order. On failure (timeout, 429, 500), next provider is tried. Circuit breaker opens for failed providers for 60s before retry.

Client sees no difference — same JSON response format regardless of which LLM answered. Prometheus metrics track which provider is used, enabling cost analysis.

---

**Q25: How would you evaluate the quality of AI responses in production?**

**Ideal answer**: Three-tier evaluation:
1. **Automatic (continuous)**: Hallucination detection — does the answer contradict retrieved context? LLM-as-judge scoring.
2. **User signals (passive)**: Thumbs up/down feedback, copy-paste actions (positive signal), follow-up "that's wrong" messages (negative signal).
3. **Human evaluation (periodic)**: Weekly sample of 100 conversations scored by engineers against rubric: accuracy, relevance, safety.

Production monitoring: track `ai_response_latency`, `ai_token_usage`, `ai_error_rate`, feedback scores. Alert when error rate spikes or feedback score drops below threshold.

---

## Section E: Security (Q26–40)

---

**Q26: Why does TeamSpot use Firebase for initial auth instead of building its own?**

**Ideal answer**: Firebase Auth handles: OAuth provider integrations (Google, GitHub), token refresh, session management, device fingerprinting, account compromise detection, and CAPTCHA. Building equivalent infrastructure correctly would take months and require constant security maintenance.

TeamSpot treats Firebase as a credential verification layer only. Firebase ID token → exchange for TeamSpot JWT that contains `userId`, `tenantId`, `sessionId`, `roles`. The backend JWT is what authorizes API calls — not the Firebase token. This way, if Firebase has an issue, we can swap providers without changing API authorization logic.

**What interviewer evaluates**: Security architecture reasoning, build vs buy decision making.

---

**Q27: How does RBAC + ABAC + ReBAC work together in TeamSpot?**

**Ideal answer**: Three-layer permission evaluation:

**RBAC (Role-Based)**: Coarse-grained access. `ADMIN > MANAGER > MEMBER > GUEST`. Checked first — if role doesn't have permission at all, reject immediately.

**ABAC (Attribute-Based)**: Fine-grained conditions. `resource.status === 'archived' → cannot edit`. `resource.tenantId !== user.tenantId → deny`. Context-aware rules.

**ReBAC (Relationship-Based)**: Object-level. `user.id === task.assigneeId → can edit`. `projectMembership.includes(user.id) → can view`. Zanzibar-inspired graph traversal.

Decision: RBAC → ABAC → ReBAC. First check to fail = deny. All three must pass = allow.

---

**Q28: What is a timing attack and how does TeamSpot prevent it?**

**Ideal answer**: A timing attack leaks information through response time differences. Example: login endpoint that returns "user not found" faster than "wrong password" — attacker can enumerate valid usernames.

Prevention: constant-time comparison for secrets using `crypto.timingSafeEqual()` in Node.js. This ensures comparison time doesn't vary based on how many characters match. Same response time for "user not found" and "wrong password" — attacker gains no information.

> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

---

**Q29: How would you respond to a security researcher reporting a SQL injection vulnerability?**

**Ideal answer**: MongoDB isn't SQL, so traditional SQL injection doesn't apply. However, NoSQL injection is real. MongoDB is vulnerable to operator injection: `{ username: { $gt: "" } }` can match all users if user input is not validated.

Prevention: Mongoose schemas validate all document types at write time. For query inputs, Joi/Zod validation strips non-string values from query parameters. Rate limiting prevents automated enumeration even if validation has gaps.

**What interviewer evaluates**: Do you know MongoDB-specific security risks? Are you dismissive or thorough?

---

**Q30: What data does TeamSpot encrypt and how?**

**Ideal answer**:
| Data Type | Encryption | Key Management |
|-----------|------------|----------------|
| Passwords | bcrypt (never stored plaintext) | No key — one-way hash |
| JWTs | HMAC-SHA256 signature | `JWT_SECRET` env var |
| Field-level sensitive data | AES-256-GCM | `ENCRYPTION_KEY` env var |
| Data in transit | TLS 1.3 (Nginx) | Certificate auto-renewed |
| Data at rest | MongoDB Atlas encryption, Redis AOF encryption | Atlas/cloud managed |
| Mobile tokens | iOS Keychain / Android Keystore | OS-managed |

AES-256-GCM for field-level encryption (custom fields, PII) in `core/crypto/field-encryption.js` — key is 32-byte random from `ENCRYPTION_KEY` env var, stored in Kubernetes Secret.

---

## Section F: Infrastructure & DevOps (Q31–45)

---

**Q31: How does TeamSpot achieve zero-downtime deployments?**

**Ideal answer**: Kubernetes Rolling Update strategy:
> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

New pods must pass readiness probes before old pods are terminated. readinessProbe checks `/health/ready` which verifies MongoDB, Redis, and Kafka connections.

Additionally: database migrations are backward-compatible (never drop columns/fields used by old code), feature flags allow new code paths to be disabled if problems appear.

**What interviewer evaluates**: K8s knowledge + deployment strategy reasoning.

---

**Q32: What does TeamSpot's CI/CD pipeline do before deploying to production?**

**Ideal answer**:
```
CI (every push):
  1. ESLint + Prettier (fast fail on code style)
  2. Vitest unit tests
  3. Integration tests against MongoDB in-memory
  4. npm audit (dependency vulnerability scan)
  5. Secret scanning (no hardcoded credentials)
  6. Docker build (validates Dockerfile)

CD (on main branch merge):
  1. Docker build + push to registry (multi-stage, production image)
  2. kubectl apply (rolling update to staging)
  3. Smoke tests against staging (5 critical API endpoints)
  4. Manual approval gate for production
  5. kubectl apply to production
  6. Monitor error rate for 15 minutes → auto-rollback if >5% error spike
```

**What interviewer evaluates**: Practical CI/CD knowledge, safety thinking.

---

**Q33: How do you handle secret rotation without downtime?**

**Ideal answer**: Kubernetes Secrets can be updated without pod restart if mounted as volume files (not env vars). TeamSpot mounts `JWT_SECRET` as a volume — pods see the new secret within 60 seconds of Kubernetes propagation.

For JWT: dual-key approach during rotation. Sign new tokens with new key. Verify accepts both old and new key. After 15 minutes (all old tokens expired), disable old key.

For MongoDB passwords: Atlas supports credential rotation. Update K8s Secret, pods refresh connection string from volume.

---

**Q34: What is the difference between liveness and readiness probes in Kubernetes?**

**Ideal answer**:
- **Liveness**: "Is this pod alive?" Fail → K8s kills and restarts pod. Check: `GET /health/live` returns 200 if process is running (not deadlocked).
- **Readiness**: "Is this pod ready to receive traffic?" Fail → K8s removes pod from load balancer (stops sending traffic), but doesn't restart it. Check: `GET /health/ready` validates MongoDB + Redis + Kafka connectivity.

Startup probe: during initial startup, readiness checks may fail (slow startup). startupProbe gives extra time before liveness checks begin.

**What interviewer evaluates**: K8s operational knowledge — many engineers confuse these.

---

**Q35: How would you debug a memory leak in production?**

**Ideal answer**:
1. **Identify**: Prometheus `process_resident_memory_bytes` growing monotonically over hours
2. **Confirm**: `kubectl exec` into pod, `node --inspect` — attach Chrome DevTools memory profiler
3. **Heap snapshot**: take snapshot at T+0, T+1hr, T+2hr — look for what's growing
4. **Common causes in TeamSpot**:
   - Socket.IO listeners not removed on disconnect
   - Mongoose query result not garbage collected (large object in closure)
   - LangChain conversation history growing unbounded
5. **Fix**: Add cleanup in disconnect handlers. Limit conversation history size. Add `--max-old-space-size` limit to force OOM crash instead of slow leak.

---

## Section G: Scalability (Q36–50)

---

**Q36: How does TeamSpot scale from 1 tenant to 10,000 tenants?**

**Ideal answer**:
- **1–100 tenants**: Single MongoDB instance, single K8s deployment. No special handling.
- **100–1,000 tenants**: MongoDB Atlas auto-scaling. Redis cluster for session/cache. Kafka for event streaming.
- **1,000–10,000 tenants**: MongoDB compound indexes become critical (tenantId prefix on all). Redis data partitioned by tenantId to prevent hot keys. K8s HPA maintains 3–20 pods.

The key insight: multi-tenant architecture (shared collections + row-level isolation) means the infrastructure is already built for this scale. The challenge at 10,000 tenants is data volume, not architectural changes.

---

**Q37: What's the difference between horizontal and vertical scaling? When do you use each?**

**Ideal answer**:
- **Vertical** (bigger machine): Easy to implement, no code changes, but has a ceiling (single machine limit), single point of failure, expensive at top tier.
- **Horizontal** (more machines): Requires stateless design, load balancer, distributed state (Redis). Scales to arbitrary size. TeamSpot's default.

Vertical first for: databases (MongoDB Atlas instance size → faster disks, more RAM = dramatic performance gain). Horizontal for: API pods (stateless, easy to add pods).

**Senior perspective**: Don't dismiss vertical scaling. Doubling MongoDB RAM is often cheaper and faster than complex sharding. Always measure before assuming horizontal scaling is needed.

---

**Q38: How would you cache effectively without serving stale data?**

**Ideal answer**: Cache-aside pattern with event-driven invalidation:
> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

**What not to do**: time-based expiry only (stale window too long for collaborative data). Write-through cache (adds write latency for data not frequently read).

---

**Q39: How do you estimate capacity requirements for TeamSpot?**

**Ideal answer**: Back-of-envelope math:
```
Assume: 10,000 DAU, each makes 200 API requests/day
Requests/day: 2M
Requests/second: 2M / 86,400 ≈ 23 RPS average

Peak factor 10x: 230 RPS peak
Per pod capacity (Node.js): ~1,000 RPS (CPU-bound at 300ms avg response)
Pods needed: 230 / 1,000 ≈ 1 pod (but run minimum 3 for HA)

MongoDB: 230 RPS × 5 DB calls avg = 1,150 queries/second
MongoDB can handle: ~10,000-50,000 QPS (depends on query complexity)
One MongoDB Atlas M30 is sufficient

Redis: 230 RPS × 2 cache hits = 460 ops/second
Redis handles: millions of ops/second → far below limits
```

**What interviewer evaluates**: Can you reason from first principles without knowing exact numbers? Order-of-magnitude thinking matters more than precision.

---

**Q40: What is connection pooling and why does it matter?**

**Ideal answer**: Each MongoDB query requires a connection. Opening/closing TCP connections is expensive (3-way handshake, TLS negotiation, authentication). Connection pooling maintains a pre-opened pool of connections that queries borrow and return.

Mongoose default `maxPoolSize: 10` = 10 concurrent MongoDB operations per pod. With 3 pods: 30 total MongoDB connections. At 230 RPS with 50ms avg query time: 230 × 0.05 = 11.5 concurrent queries — right at pool limit, but OK.

At 1,000 RPS: 1,000 × 0.05 = 50 concurrent queries. Pool saturates, queries queue. Either: increase maxPoolSize, optimize query time, or add more pods.

---

## Section H: Architecture Design Questions (Q41–60)

---

**Q41: Design TeamSpot's notification system from scratch.**

**Ideal answer**:
```
Requirements:
  - In-app (WebSocket), email, push (FCM/APNs), SMS
  - At-least-once delivery
  - User notification preferences (opt-out per channel per type)
  - Notification deduplication (don't send same notification twice)
  - Batch digest option (hourly/daily digest instead of per-event)

Architecture:
  1. DomainEventBus receives: task.assigned, meeting.starting, mention.created
  2. NotificationService:
     a. Load user preferences from cache
     b. Skip if user opted out for this type + channel
     c. Check deduplication (Redis SET with 1hr TTL)
     d. Build notification payload
     e. Fan out to appropriate queue per channel:
        - In-app → Redis pub/sub → Socket.IO
        - Email → RabbitMQ email.queue
        - Push → RabbitMQ push.queue
        - SMS → RabbitMQ sms.queue (future)
  3. Workers consume queues with retry logic

Digest mode:
  - Set 'digest_hourly' preference → don't send immediate
  - Cron at :00 each hour: aggregate unsent notifications → single email
```

---

**Q42: How would you add a feature to share a project with external users (guests)?**

**Ideal answer**: This requires extending the permission model, not just adding a user type:

1. **Guest user type**: `role: 'GUEST'` with tenant-scoped permissions
2. **Resource-level sharing**: `project.guestAccess: [{ userId, permissions: ['read'] }]` 
3. **Invite flow**: Generate time-limited invite URL with signed token (`JWT` with `projectId + permissions + expiry`). External user clicks → creates guest account or links existing account.
4. **Permission evaluation**: ReBAC layer checks `project.guestAccess` — guests can only access the specific project they were invited to, not workspace-wide data.
5. **Audit trail**: All guest actions logged with `role: GUEST` in audit.
6. **Expiry**: Guest access expires after `WorkspaceConfig.GUEST_ACCESS_DAYS` (90 days by default).

---

**Q43: Walk through the data flow when a user creates a task with an attachment.**

**Ideal answer**:
```
1. Client: POST /projects/{id}/tasks with multipart form (title, description, file)
2. API Gateway: auth middleware validates JWT, extracts userId + tenantId
3. Rate limiter: checks token bucket for userId
4. File upload handler: streams file to Cloudinary (chunked upload, no temp file on disk)
5. Cloudinary returns: { url, publicId, format, bytes }
6. TaskService.create():
   a. Creates task document with attachment metadata (url, NOT file bytes)
   b. emits task.created event
7. EventBus handlers fire concurrently:
   a. AuditHandler: logs creation
   b. NotificationHandler: notifies assignee
   c. SearchIndexHandler: indexes task in OpenSearch
   d. AIHandler: queues document for embedding (if description > 100 chars)
8. API returns: 201 Created with task JSON including attachment URL
9. Mobile client: displays task with Cloudinary CDN URL (no local file needed)
```

---

## Section I: Short Answer (Q44–60)

**Q44**: Why use ULID instead of UUID v4?  
**Answer**: ULIDs are lexicographically sortable (encode timestamp prefix). Inserting ULIDs into MongoDB `_id` is index-friendly — documents are inserted in roughly chronological order, reducing B-tree rebalancing. UUID v4 is random → B-tree fragmentation at high insert rates.

**Q45**: What is the thundering herd problem?  
**Answer**: When a shared resource (cache) expires simultaneously, all requesters hit the backing store at once. Prevent with: jitter on TTL, single-writer lock (Redis SETNX), and background refresh before expiry.

**Q46**: What is eventual consistency?  
**Answer**: A distributed system guarantees that if no new updates are made, all replicas will eventually converge to the same value. TeamSpot uses eventual consistency for notifications, search indexing, and analytics — where brief staleness is acceptable. Uses strong consistency for payment events and audit logs.

**Q47**: What is the outbox pattern?  
**Answer**: Write the domain event to a database table (same transaction as state change), then a separate process reads from the outbox and publishes to Kafka. Guarantees at-least-once delivery of events without 2-phase commit.

**Q48**: How do you handle database schema migrations in production?  
**Answer**: Backward-compatible migrations only. Never rename or drop fields used by running code. Add-only first, then backfill, then remove old field in a separate deploy.

**Q49**: What is blue-green deployment vs canary deployment?  
**Answer**: Blue-green: two identical production environments; flip traffic from blue to green. Zero downtime, but double infrastructure cost. Canary: gradually route % of traffic to new version (1% → 10% → 100%). Slower rollout but catches issues before full exposure.

**Q50**: What is idempotency and why is it important for payment processing?  
**Answer**: An operation is idempotent if performing it multiple times has the same effect as once. For payments: if the client retries due to network timeout, the second request must not charge twice. Stripe handles this via `idempotencyKey` header — pass the same key with retries.

---

## Section J: Principal Engineer Thinking (Q51–65)

---

**Q51: TeamSpot has grown. The auth service is now the #1 source of incidents. How do you approach extracting it as a separate service?**

**Ideal answer**: Strangler fig pattern:
1. Create `AuthService` interface in the monolith abstracting all auth operations
2. Monolith initially implements it locally (no change)
3. Build standalone auth service in parallel
4. Swap implementation behind feature flag (shadow mode: call both, compare results)
5. Monitor for behavioral differences in staging
6. Gradually route production traffic: 1% → 10% → 100%
7. Remove monolith auth code

The key insight: never do a hard cutover. Always have a rollback path.

**What interviewer evaluates**: Migration discipline, risk management, strangler fig pattern knowledge.

---

**Q52: A Principal Engineer review says "your API design leaks domain concepts." What might they mean?**

**Ideal answer**: Domain leakage means: internal implementation details are visible in the API. Examples:
- Endpoint returns `_id` (MongoDB internal) instead of `id`
- Error message says "MongoServerError: Document failed validation" instead of user-friendly message
- Endpoint named `/tasks/updateStatus` (CRUD operation) instead of `/tasks/:id/complete` (domain action)
- API exposes all fields from DB document, including internal fields like `version`, `tenantId`

Good API design: consumers should be insulated from your internal schema. Response DTOs transform domain objects into API-appropriate shapes.

---

**Q53: How do you think about technical debt?**

**Ideal answer**: Technical debt is like financial debt — sometimes it's a deliberate, sensible investment. Taking a shortcut to ship a feature faster is acceptable IF: it's documented, it has a clear payoff plan, and the interest (maintenance cost) is manageable.

Unacceptable debt: security shortcuts (interest = data breach), missing tests (interest = regression fear → velocity reduction), no observability (interest = blind production system).

The worst debt: invisible debt — code that works but nobody understands. This compounds silently until it collapses.

TeamSpot approach: track debt in code comments `// TECH_DEBT: [explanation, Jira-link]` and review quarterly.

---

**Q54: The CEO wants to add blockchain for document signing. How do you respond?**

**Ideal answer**: As a principal engineer, I'd ask: what problem are we solving? Document signing for legal validity is solved by established, audited solutions: DocuSign, Adobe Sign, or AWS KMS-based digital signatures. These are legally recognized, compliance-audited, and integrate in a day.

Blockchain adds: immutability, decentralization, and tamper-proof audit — valuable if there's no trusted central authority. For TeamSpot internal documents, we ARE the trusted authority. Blockchain adds complexity and latency without solving a real problem.

I'd present alternatives, explain the tradeoffs honestly, and let business make an informed decision. If they still want blockchain after understanding the tradeoffs, we implement it. Engineering advises; business decides.

**What interviewer evaluates**: Can you push back constructively without being dismissive? Do you understand when technology solves vs creates problems?

---

**Q55: How do you onboard a new engineer to the TeamSpot codebase?**

**Ideal answer**: Day 1: environment setup (Docker Compose), run tests, find a small bug to fix independently.

Week 1: read the architecture documentation (this system design workspace). Pair-program one feature end-to-end (route → controller → service → repository → model → test).

Week 2: own a module. Review PRs from others. Write docs for anything unclear.

Month 1: lead a feature. Participate in incident response. Architecture review participation.

The onboarding goal: a new engineer should ship a small feature solo in week 2. If they can't, the codebase is too complex or the docs are insufficient. Both are engineering problems, not people problems.

---

## Section K: Behavioral + System Design Integration (Q56–65)

---

**Q56–Q65 are open-ended design questions — practice by designing these end-to-end:**

56. Design TeamSpot's workflow automation engine from scratch.
57. How would you implement real-time collaborative document editing (Google Docs-style)?
58. Design an analytics system that can answer "tasks completed per user per week" without impacting the OLTP database.
59. How would you implement a billing system that handles plan upgrades, downgrades, and prorated charges?
60. Design TeamSpot's search experience — how would you make it find the right result for "q4 planning" even if the task is titled "fourth quarter roadmap"?
61. How would you implement SSO (SAML 2.0) for enterprise customers?
62. Design a system that can export all workspace data for GDPR compliance within 24 hours.
63. How would you implement end-to-end encryption for private channels?
64. Design TeamSpot's mobile offline sync mechanism.
65. How would you build an audit trail that is tamper-proof?

**For each**: follow the framework: Requirements → Capacity → High-Level Design → Deep Dive → Tradeoffs → Bottlenecks → Evolution Path.

---

## Final Advice

The difference between a senior engineer and a principal engineer in system design interviews:

**Senior**: Gives correct answers. Knows the patterns. Can implement the solution.

**Principal**: Asks why. Challenges the requirements. Identifies the tradeoffs. Knows when NOT to use a pattern. Thinks about the organization that will maintain this system in 5 years.

When you get a system design question about TeamSpot, don't just recite what you built. Explain WHY each decision was made, what alternatives you considered, and under what conditions you'd make a different choice.

That reasoning IS the architecture.
