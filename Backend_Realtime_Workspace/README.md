# TeamSpot — Backend

> **Purpose**: Authoritative codebase map for AI assistants and developers. Use this to locate files, understand data flow, and navigate the architecture. Always update this when adding/moving modules.
>
> **What it is**: Enterprise workspace collaboration platform — teams, projects, tasks, issues, tickets, meetings, real-time chat, video/voice (LiveKit), AI agent (LangChain/LangGraph + RAG + MCP), push notifications, billing (Stripe), and more.

**Stack**: Node.js 20 · Express 5 · MongoDB/Mongoose · Redis · Kafka · RabbitMQ · Socket.IO · LiveKit · Firebase Auth · Cloudinary · LangChain/LangGraph · OpenSearch · OpenTelemetry · Prometheus · Sentry

---

## Directory Map

```
Backend_Realtime_Workspace/
├── index.js                    # Entry point — Express app, middleware stack, service bootstrap
├── package.json                # Dependencies + npm scripts (dev/start/test/lint/format)
├── Makefile                    # Shortcuts: make dev/docker-up/k8s-apply/kafka-init
├── Dockerfile                  # Multi-stage production build (node:20-alpine)
├── docker-compose.yaml         # Local stack: MongoDB, Redis, Kafka, LiveKit, Mailhog, Qdrant
│
├── .husky/
│   ├── pre-commit              # npx lint-staged (eslint + prettier on staged files)
│   └── commit-msg              # npx commitlint (conventional commits enforced)
├── .commitlintrc.json          # Types: feat/fix/docs/style/refactor/perf/test/build/ci/chore/revert
├── .lintstagedrc.json          # *.js -> eslint+prettier; *.json/md/yaml -> prettier
│
├── .github/workflows/
│   ├── ci.yml                  # PR: lint, format-check, unit tests, npm audit, TruffleHog scan
│   └── cd.yml                  # main: Docker build+push GHCR -> kubectl rolling deploy
│
├── config/
│   ├── env.config.js           # All env vars — TeamSpot only (no stale blockchain vars)
│   ├── constants.js            # HttpStatus, ErrorCodes, SocketEvents, KafkaTopics, CacheTTL
│   ├── mongo.config.js         # connectDB() / disconnectDB() using MONGO_URI
│   └── firebase-admin.config.js # Firebase Admin SDK init
│
├── core/                       # Cross-cutting concerns — imported by all modules
│   ├── auth/
│   │   ├── firebase-auth.middleware.js  # firebaseAuthMiddleware (CANONICAL — use in all routes)
│   │   │                               # optionalAuth — attach user if present, non-blocking
│   │   ├── permission-engine.js         # RBAC + ABAC + ReBAC (Zanzibar-inspired)
│   │   ├── permission.middleware.js     # requirePermission(action, resource) factory
│   │   └── tenant.middleware.js         # extract tenantId -> req.tenant (global middleware)
│   ├── base/
│   │   ├── base.controller.js  # asyncHandler(fn) — wraps async routes, forwards errors
│   │   ├── base.repository.js  # BaseRepository — CRUD + pagination over Mongoose
│   │   └── base.service.js     # BaseService — generic with eventBus integration
│   ├── cache/
│   │   └── cache-keys.js       # Typed key factories: user(id), project(id), channel(id)
│   ├── crypto/
│   │   └── encryption.service.js  # AES-256-GCM encrypt/decrypt, PBKDF2 key derivation
│   ├── data/
│   │   ├── privacy.js          # GDPR: redactPII(), anonymize(), buildDataExportPayload()
│   │   └── terms-of-service.js # Legal document content
│   ├── errors/
│   │   ├── app-error.js        # AppError + factories (badRequest/notFound/etc.) — CANONICAL
│   │   └── error-handler.js    # globalErrorHandler — maps errors to JSON + Sentry
│   ├── events/
│   │   ├── event-bus.js        # DomainEventBus (EventEmitter + idempotency)
│   │   └── event-contracts.js  # Domain event name constants
│   ├── structures/
│   │   └── index.js            # LRU cache, priority queue, trie — algorithmic primitives
│   └── utils/
│       ├── api-response.js     # success() / created() / paginated() / error() — standard JSON
│       ├── extentions.js       # MIME types, allowed file extensions
│       ├── id-generator.js     # generateInviteCode(), generateTicketNumber(), generateProjectKey()
│       ├── meeting-code.js     # xxx-xxxx-xxx format meeting code
│       ├── pagination.js       # parsePagination(query), paginationMeta(), parseSort()
│       └── retry.js            # withRetry(fn, opts) — exponential backoff + jitter
│
├── infrastructure/             # External service adapters — initialized once at startup
│   ├── billing/stripe.service.js    # createCheckoutSession, invoices, subscriptions, webhooks
│   ├── database/mongoose.js         # Mongoose lifecycle, connection events
│   ├── kafka/
│   │   ├── kafka.service.js    # initKafka(), publishEvent(topic, key, payload), healthCheck()
│   │   └── kafka-topics.js     # All Kafka topic name constants
│   ├── livekit/livekit.service.js   # initLiveKit(), generateToken(room, identity, opts)
│   │                                # listRooms(), deleteRoom(), listParticipants(), removeParticipant()
│   ├── mailer/
│   │   ├── mailer.service.js   # initMailer(), sendEmail(), sendBulkEmails()
│   │   ├── mail-content.js     # EmailContentGenerator: welcomeEmail, inviteEmail, twoFACode,
│   │   │                       # meetingReminder, taskAssigned, digestNotification, billingAlert
│   │   └── mail-render.js      # Handlebars HTML email renderer with TeamSpot branding
│   ├── pdf/
│   │   ├── document-parser.js  # TeamSpot document parser for RAG ingestion:
│   │   │                       # extractTextFromPDF(), extractTextFromDocx(), parseSpreadsheet()
│   │   │                       # parseMarkdown(), parseDocument(file) -> {text, metadata}
│   │   └── pdf-renderer.js     # generatePDFFromTemplate({templateName, data}) via Puppeteer
│   ├── push/
│   │   ├── fcm.service.js      # sendFCM(), sendMultipleFCM(), sendToTopic(), subscribeToTopic()
│   │   └── fcm-helpers.js      # FCM payload builders per notification type
│   ├── rabbitmq/rabbitmq.service.js # initRabbitMQ(), publishToQueue(), consumeQueue(), publishDelayed()
│   ├── redis/redis.service.js       # initRedis(), get/set/del/expire, pub/sub, getRedisClient()
│   ├── search/search.service.js     # OpenSearch: index(), search(), deleteDoc(), reindex(), bulkIndex()
│   ├── storage/cloudinary.service.js # initCloudinary(), upload.single/array, uploadBuffer(), deleteAsset()
│   └── websocket/
│       ├── websocket.service.js # initWebSocket(server) — Socket.IO 4 + Redis adapter
│       │                        # Rooms: user:{id}, meeting:{id}, channel:{id}, workspace:{id}
│       │                        # emitToUser(userId, event, data), emitToRoom(room, event, data)
│       ├── presence.service.js  # updatePresence(), getPresence() via Redis HSET
│       └── socket-events.js     # Socket event name constants
│
├── agent/                      # AI Agent subsystem — LangChain/LangGraph
│   ├── index.js                # initAgent() bootstrap; re-exports all agent classes
│   ├── runtime/
│   │   ├── agent-executor.js   # AgentExecutor.execute({input, userId, tenantId, workspaceId,
│   │   │                       #   permissions, conversationId, stream, res})
│   │   ├── fallback.js         # ModelFallback.getModel() — priority chain:
│   │   │                       #   OpenAI gpt-4o -> Anthropic claude-sonnet ->
│   │   │                       #   Google gemini-2.0-flash -> HuggingFace Mistral-7B
│   │   ├── streaming.js        # streamResponse(model, messages, res) — SSE token streaming
│   │   └── tool-registry.js    # ToolRegistry — register(name, config), getTools(ctx+permissions)
│   │                           # Builtins: search_workspace, create_task, list_tasks, get_meetings,
│   │                           # summarize_document, create_meeting, get_project_status
│   ├── knowledge/
│   │   ├── rag-pipeline.js     # RAGPipeline.ingest({content, metadata}) — chunk->embed->store
│   │   │                       # RAGPipeline.query({query, userId, tenantId}) — ACL-filtered search
│   │   ├── retriever.js        # Retriever.search(query, ctx) — ACL-aware semantic search
│   │   ├── embeddings.js       # generateEmbeddings(texts) — fallback:
│   │   │                       #   OpenAI text-embedding-3-small -> Cohere embed-multilingual-v3
│   │   │                       #   -> HuggingFace all-MiniLM-L6-v2 -> dev hash fallback
│   │   └── chunking.js         # chunkDocument(text, {strategy, chunkSize, overlap})
│   ├── memory/conversation-memory.js # In-memory + Redis persistence
│   ├── mcp/
│   │   ├── mcp-server.js       # MCPServer — tools/list, tools/call, resources/*
│   │   ├── mcp-tools.js        # MCP tool definitions: createTask, searchDocs, listProjects
│   │   └── mcp-resources.js    # workspace://* and project://* MCP resource URIs
│   ├── governance/
│   │   ├── prompt-guard.js     # Injection/jailbreak detection -> {blocked, reason}
│   │   └── audit-logger.js     # Log all agent actions: tools, token usage, latency
│   └── consumers/ai-kafka-consumer.js # teamspot.ai.stream -> WebSocket token push
│
├── middlewares/
│   ├── auth.middleware.js      # authenticate() — Firebase verify + MongoDB User.findOne()
│   │                           # Prefer core/auth/firebase-auth.middleware.js for lighter-weight
│   ├── security.middleware.js  # securityHeaders() Helmet, corsConfig(), xssProtection
│   ├── ratelimit.middleware.js  # apiLimiter (100rpm), authLimiter (10rpm), aiLimiter (30rpm)
│   ├── request-logger.middleware.js # requestId (UUID per request), structured HTTP log
│   ├── validate.middleware.js   # validate(schema) — express-validator handler
│   ├── helper.middleware.js     # noCache, cacheControl(ttl), setTenant, sanitizeBody
│   ├── errorhandler.middleware.js # LEGACY — use core/errors/app-error.js for new code
│   └── index.js                # Barrel export
│
├── modules/                    # Feature modules — auto-discovered by module-registry.js
│   ├── module-registry.js      # registerModules(app, apiPrefix) mounts all modules
│   │
│   ├── auth/                   # 2FA: email OTP + SMS OTP + TOTP (speakeasy)
│   ├── users/                  # User profiles + referral system
│   ├── organizations/          # Multi-tenant root entity
│   ├── workspaces/             # Workspace management
│   │
│   ├── teams/                  # Team management (active module: modules/teams/ NOT modules/team/)
│   │   ├── teams/team.routes.js     # Full CRUD + invite + bulk-permissions + analytics
│   │   └── teams/models/team.model.js
│   │
│   ├── projects/               # Project management + timeline + progress + attachments
│   ├── tasks/                  # Task tracking linked to projects
│   ├── issues/                 # Issue tracking
│   ├── tickets/                # Support ticket system with SLA
│   ├── channels/               # Messaging channels (Slack-like)
│   │
│   ├── communication/          # LiveKit video/voice + VoIP + direct messages
│   │   ├── communication.routes.js  # POST /rooms/token|create, GET|DELETE /rooms
│   │   │                            # GET /rooms/:name/participants, POST /remove-participant
│   │   │                            # POST /calls/initiate, PUT /calls/:id/accept|end|reject
│   │   │                            # GET /calls/history, POST|GET /messages, DELETE /messages/:id
│   │   ├── video.controller.js / video.service.js       # LiveKit room + token management
│   │   ├── voip-call.controller.js / voip-call.service.js  # VoIP state machine (Redis-backed)
│   │   └── chat.controller.js / chat.service.js         # Direct messages + Kafka fan-out
│   │
│   ├── meetings/ / schedules/  # Meeting scheduling + advanced schedule system
│   ├── notifications/          # FCM push + in-app notifications
│   ├── documents/              # Document storage + RAG indexing pipeline
│   ├── storage/                # Media asset management via Cloudinary
│   ├── search/                 # Global full-text search via OpenSearch
│   ├── audit/                  # Immutable append-only audit log
│   ├── analytics/              # Reports + schedule analytics
│   ├── admin/                  # Tenant admin: impersonation, org stats, SLA
│   ├── billing/                # Stripe subscriptions + invoicing
│   ├── integrations/           # GitHub, Slack, Google Drive, Jira, Zoom
│   ├── workflows/              # Automation: trigger -> condition -> action
│   ├── templates/              # Email/PDF/notification template CRUD
│   ├── feedback/               # User feedback + bug reports
│   │
│   ├── ai/                     # AI agent HTTP interface
│   │   ├── ai.routes.js        # POST /chat (SSE stream), GET /conversations, GET|DELETE /conversations/:id
│   │   │                       # POST /rag/query|ingest, GET /rag/status
│   │   │                       # GET /tools, POST /tools/:name/execute, POST /summarize
│   │   ├── ai.controller.js    # chat, getConversations, getConversation, deleteConversation,
│   │   │                       # ragQuery, ragIngest, ragStatus, listTools, executeTool, summarize
│   │   ├── ai.service.js       # Wires req context -> AgentExecutor + RAGPipeline
│   │   ├── runtime/            # Module-local executor + tool registry
│   │   └── models/conversation.model.js
│   │
│   ├── identity/               # IAM: RBAC + ABAC roles, policies, user permissions
│   └── legal/                  # Public legal pages (no auth required)
│
├── observability/
│   ├── logger.js               # createLogger(context) — pino + requestId correlation
│   ├── prometheus.js           # metricsMiddleware, /metrics endpoint
│   ├── sentry.js               # initializeSentry(), setupSentryExpress(), captureException()
│   ├── grafana.js              # /health, /health/ready, /health/detailed, registerHealthChecker()
│   └── tracing.js              # OpenTelemetry distributed tracing
│
├── workers/                    # RabbitMQ consumers — background job processors
│   ├── index.js                # initWorkers() — starts all workers post-infra
│   ├── notification.worker.js  # email.send + push.notification queues
│   ├── media.worker.js         # media.process (compress/transcode) + media.thumbnail
│   ├── audit.worker.js         # audit.log -> append-only AuditLog writes
│   ├── ai.worker.js            # ai.embedding + ai.rag_ingest -> agent/ RAG pipeline
│   ├── workflow.worker.js      # workflow.execute -> automation rule evaluation
│   └── analytics.worker.js     # analytics.aggregate -> metric aggregation
│
├── k8s/
│   ├── namespace.yaml          # namespace: teamspot
│   ├── deployment.yaml         # 3 replicas, RollingUpdate, Prometheus annotations, non-root
│   ├── service.yaml            # ClusterIP port 5000
│   ├── configmap.yaml          # Non-secret env (NODE_ENV, PORT, LOG_LEVEL, API_VERSION)
│   └── secrets.yaml            # Sensitive env (MONGO_URI, JWT_SECRET, AI keys, Stripe)
│
├── nginx/
│   ├── nginx.conf              # rate-limit zones (TeamSpot), upstream teamspot_api keepalive 64
│   └── default.conf            # Route limits, WebSocket upgrade, AI SSE no-buffering, security headers
│
└── terraform/
    ├── main.tf                 # VPC, EKS cluster, managed node groups
    ├── providers.tf / variables.tf / outputs.tf
    ├── database.tf             # MongoDB Atlas / DocumentDB
    ├── redis.tf                # ElastiCache Redis (multi-AZ, encrypted)
    ├── cloudflare.tf           # CDN + DNS + WAF + DDoS protection
    └── terraform.tfvars.example
```

---

## Authentication Flow

```
Client -> Authorization: Bearer <Firebase_ID_Token>

Path A — Preferred (all routes):
  core/auth/firebase-auth.middleware.js -> firebaseAuthMiddleware
    1. admin.auth().verifyIdToken(token)  <- no DB round-trip
    2. req.user = { uid, email, emailVerified, displayName, picture, authProvider }
    3. Invalid -> 401 AppError

Path B — Full user doc (when business logic needs Mongoose document):
  middlewares/auth.middleware.js -> authenticate()
    1. Same Firebase verify
    2. User.findOne({ firebaseUid }) in MongoDB
    3. req.user = full Mongoose UserInfo document
    4. Not found -> 404 (never auto-creates)
```

---

## AI Agent Architecture

```
POST /api/v1/ai/chat
  -> firebaseAuthMiddleware -> ai.controller.chat()
  -> ai.service.handleChat({input, userId, tenantId, workspaceId, permissions, stream})

  AgentExecutor.execute()
    1. PromptGuard.check(input)           <- injection/jailbreak/exfil patterns
    2. ConversationMemory.getHistory()    <- Redis-backed, last 20 messages
    3. ModelFallback.getModel()
         OpenAI gpt-4o
         -> Anthropic claude-sonnet-4
         -> Google gemini-2.0-flash
         -> HuggingFace mistralai/Mistral-7B-Instruct-v0.3  (last fallback)
    4. ToolRegistry.getTools(permissions)  <- permission-filtered
    5. LangGraph tool-calling loop (max 10 iterations)
    6. ConversationMemory.addMessage()    <- persist turn

  search_workspace tool -> RAGPipeline.query()
    -> generateEmbeddings(query)
         OpenAI text-embedding-3-small
         -> Cohere embed-multilingual-v3.0
         -> HuggingFace sentence-transformers/all-MiniLM-L6-v2
         -> dev hash (offline fallback)
    -> vectorStore.similaritySearch(filter: tenantId + workspaceId + ACL)
    -> rerank by recency + relevance
```

---

## Queue Architecture

### Kafka — Event Streaming
| Topic | Producer | Consumer |
|-------|----------|----------|
| `teamspot.audit.events` | All modules | audit.worker.js |
| `teamspot.ai.embedding` | documents, storage | ai.worker.js -> vector DB |
| `teamspot.ai.rag_ingest` | documents | ai.worker.js -> RAGPipeline |
| `teamspot.analytics.events` | All modules | analytics.worker.js |
| `teamspot.ai.stream` | AgentExecutor | ai-kafka-consumer.js -> WebSocket |

### RabbitMQ — Task Queues
| Queue | Worker | Purpose |
|-------|--------|---------|
| `teamspot.email.send` | notification.worker.js | SMTP email delivery |
| `teamspot.push.notification` | notification.worker.js | FCM push |
| `teamspot.media.process` | media.worker.js | Compress/transcode |
| `teamspot.media.thumbnail` | media.worker.js | Thumbnail generation |
| `teamspot.audit.log` | audit.worker.js | Async audit writes |
| `teamspot.workflow.execute` | workflow.worker.js | Automation rules |
| `teamspot.analytics.aggregate` | analytics.worker.js | Metric aggregation |

---

## Data Models — Key Fields Reference

| Schema | Notable Fields |
|--------|---------------|
| `user.model.js` | firebaseUid, email, displayName, profilePicture, tenantId, orgId, workspaceIds[], permissionsLevel(super_admin/admin/manager/employee/member/guest), roleTitle, department, workType, timezone, workingHours{start,end}, socialLinks, profileCompletion(0-100), totpEnabled, inviteCode |
| `organization.model.js` | name, slug, tenantId(unique), owner, plan, quotas, settings, sso, status |
| `workspace.model.js` | name, slug, tenantId, orgId, owner, members[], settings, isDefault |
| `team.model.js` | name, slug, tenantId, orgId, type, members[], invites[], settings, stats, isActive |
| `project.model.js` | name, key(PROJ-001), tenantId, workspaceId, status, priority, collaborators[], attachments[], timeline[], progress(0-100), starred, archived, budget |
| `task.model.js` | title, tenantId, projectId, assignedTo, createdBy, status(todo/in-progress/done/blocked), priority, checklist[], comments[], labels[], sortOrder |
| `issue.model.js` | title, tenantId, projectId, assignedTo, reporter, severity, environment, comments[], linkedIssues[] |
| `ticket.model.js` | ticketNumber, tenantId, orgId, reporter, assignedTo, category, status, priority, sla, comments[] |
| `channel.model.js` | name, slug, tenantId, workspaceId, type(public/private/dm), topic, members[], settings, createdBy |
| `notification.model.js` | tenantId, recipientId, senderId, type, title, body, channel, resource, read(bool NOT isRead), priority |
| `document.model.js` | tenantId, workspaceId, file{url,size,mimeType}, metadata, parsedContent, sharedWith[], versions[], uploadedBy |
| `asset.model.js` | tenantId, filename, originalName, folder, publicId, resourceType(image/video/audio/document/raw), bytes, variants[], attachedTo, status |
| `audit-log.model.js` | tenantId, action, category, actor{userId,email,ip}, target{type,id,name}, changes{before,after} — NO updatedAt (append-only) |
| `subscription.model.js` | tenantId(unique), orgId, plan(free/starter/professional/enterprise), status, billingCycle, seats{purchased,used}, externalId(Stripe) |
| `integration.model.js` | tenantId, orgId, name, type(github/slack/google_drive/jira/zoom), config, enabled(bool NOT isActive) |
| `workflow.model.js` | tenantId, orgId, name, trigger{type,config}, conditions[], actions[], enabled, lastRun |
| `template.model.js` | tenantId, orgId, name, slug, type(email/pdf/notification/invoice), body, variables[], status |
| `feedback.model.js` | tenantId, userId, title, description, category, status, attachments[], response, metadata |
| `role.model.js` | tenantId, orgId, name, slug, permissions[{resource,actions[]}], isSystem, hierarchy |
| `conversation.model.js` | tenantId, userId, workspaceId, agentType, title, messages[], context, tokenUsage, model, status |

---

## Module File Pattern

| File | Role |
|------|------|
| `<name>.routes.js` | Router — apply auth middleware, wire URLs to controllers |
| `<name>.controller.js` | Extract req params -> call service -> respond via api-response.js |
| `<name>.service.js` | Business logic — Mongoose, Redis, Kafka, external APIs |
| `<name>.validation.js` | express-validator schemas |
| `models/<name>.model.js` | Mongoose schema — all field names authoritative here |

---

## Socket.IO Events

| Event | Direction | Purpose |
|-------|-----------|---------|
| `auth:register` | C->S | Join user:{id} room |
| `meeting:join` | C->S | Join meeting:{id} room |
| `meeting:leave` | C->S | Leave meeting room |
| `chat:message` | C->S | Broadcast to channel/meeting room |
| `chat:typing` | C->S | Typing indicator |
| `channel:join` | C->S | Join channel:{id} room |
| `presence:update` | C->S | Online/idle/offline/dnd status |
| `participant:muted` | S->C | Media state update |
| `notifications:new` | S->C | Push notification to user room |
| `ai:stream-token` | S->C | AI streaming response token |

---

## Canonical Import Paths

| Need | Import from |
|------|-------------|
| Auth middleware | `../../core/auth/firebase-auth.middleware.js` |
| AppError + factories | `../../core/errors/app-error.js` |
| Global error handler | `../../core/errors/error-handler.js` |
| API response helpers | `../../core/utils/api-response.js` |
| Logger | `../../observability/logger.js` |
| Event bus | `../../core/events/event-bus.js` |
| Cache keys | `../../core/cache/cache-keys.js` |
| Pagination | `../../core/utils/pagination.js` |
| asyncHandler | `../../core/base/base.controller.js` |
| Env config | `../../config/env.config.js` |

---

## Environment Variables

| Category | Variables |
|----------|-----------|
| App | `NODE_ENV`, `PORT`, `HOST`, `BASE_URL`, `API_VERSION` |
| Security | `FRONTEND_URL`, `CORS_ORIGINS`, `JWT_SECRET`, `JWT_EXPIRY`, `ENCRYPTION_KEY` |
| MongoDB | `MONGO_URI` |
| Firebase | `FIREBASE_SERVICE_ACCOUNT` (path to JSON file) |
| Redis | `REDIS_URL` or `REDIS_HOST`+`REDIS_PORT`+`REDIS_PASSWORD`+`REDIS_DB` |
| Kafka | `KAFKA_BROKERS`, `KAFKA_CLIENT_ID`, `KAFKA_GROUP_ID`, `KAFKA_SSL` |
| RabbitMQ | `RABBITMQ_URL` |
| LiveKit | `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_HOST` |
| Cloudinary | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` |
| SMTP | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`, `SMTP_SECURE` |
| Stripe | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` |
| AI — LLM | `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_AI_API_KEY`, `HUGGINGFACE_API_KEY` |
| AI — Embeddings | `COHERE_API_KEY` (optional Cohere fallback) |
| Vector DB | `QDRANT_URL`, `QDRANT_API_KEY` or `PINECONE_API_KEY`+`PINECONE_INDEX` |
| Search | `OPENSEARCH_URL`, `OPENSEARCH_USERNAME`, `OPENSEARCH_PASSWORD` |
| Observability | `LOG_LEVEL`, `SENTRY_DSN`, `PROMETHEUS_METRICS_ENABLED`, `OTEL_EXPORTER_OTLP_ENDPOINT` |

---

## Error Code Ranges

| Range | Domain |
|-------|--------|
| E1xxx | Auth / identity |
| E2xxx | Validation |
| E3xxx | Resource not found |
| E4xxx | Permission / authorization |
| E5xxx | Business rule violations |
| E9xxx | System / internal |

---

## Key Commands

```bash
npm run dev          # nodemon hot reload
npm run start        # production
npm run test         # vitest unit tests
npm run lint         # ESLint
npm run format       # Prettier write

make docker-up       # Start full local stack
make docker-down     # Stop stack
make k8s-apply       # kubectl apply k8s/ manifests
make kafka-init      # Create all Kafka topics
```

---

## Known Legacy / Stale Code

| File | Issue | Action |
|------|-------|--------|
| `middlewares/errorhandler.middleware.js` | Duplicate AppError; refs old `../logs/` path | Use `core/errors/app-error.js` for new code |
| `modules/team/` (singular) | Pre-refactor module — not mounted | Safe to delete |
| `infrastructure/pdf/document-parser.js` (old) | Was VoteSecure question-extractor | Replaced with TeamSpot document parser |
| `config/env.config.js` header | Was labeled VoteSecure with blockchain vars | Cleaned up — TeamSpot only |
