# 05 — Real-Time Infrastructure
# TeamSpot: WebSocket Architecture, Presence System, Kafka Streaming & LiveKit

---

## 1. Real-Time Architecture Overview

TeamSpot uses three distinct real-time subsystems, each with a specific responsibility:

```
┌─────────────────────────────────────────────────────────────────┐
│              REAL-TIME INFRASTRUCTURE                            │
│                                                                   │
│  Socket.IO (WebSocket)    Kafka Streaming     LiveKit (WebRTC)  │
│  ─────────────────────    ───────────────     ───────────────── │
│  • Chat messages          • Event fanout       • Video rooms     │
│  • Presence updates       • AI token push      • Voice calls     │
│  • Notifications          • Analytics          • Screen share    │
│  • Task status changes    • Audit log          • Recording       │
│  • Typing indicators      • Search indexing    • SFU (Selective  │
│  • Cursor movements       • RAG ingestion        Forwarding)     │
│  • Collaborative state    • Worker dispatch                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Socket.IO Architecture

### Initialization

> **See** [`Backend_Realtime_Workspace/infrastructure/websocket/websocket.service.js`](../Backend_Realtime_Workspace/infrastructure/websocket/websocket.service.js) — `initWebSocket()` — Socket.IO server + Redis adapter for multi-pod fanout

### Room Architecture

Socket.IO rooms are the fanout unit. Each client joins rooms based on their access context:

```
user:{userId}           — personal notification stream
workspace:{workspaceId} — workspace-wide broadcasts
channel:{channelId}     — channel messages
meeting:{meetingId}     — meeting events (participants, recording status)
project:{projectId}     — project activity feed
```

> **See** [`Backend_Realtime_Workspace/middlewares/validate.middleware.js`](../Backend_Realtime_Workspace/middlewares/validate.middleware.js) — `validateRequest()` — Joi schema validation middleware factory

### Emit Patterns

> **See** [`Backend_Realtime_Workspace/infrastructure/websocket/socket-events.js`](../Backend_Realtime_Workspace/infrastructure/websocket/socket-events.js) — Socket.IO event handlers — auth register, chat, presence, meeting, AI stream

### Complete Socket Event Catalogue

> **See** [`Backend_Realtime_Workspace/infrastructure/websocket/socket-events.js`](../Backend_Realtime_Workspace/infrastructure/websocket/socket-events.js) — Socket.IO event handlers — auth register, chat, presence, meeting, AI stream

---

## 3. Presence System

Presence tracks user online/offline/away state with sub-second updates.

### Storage: Redis HSET

> **See** [`Backend_Realtime_Workspace/infrastructure/redis/redis.service.js`](../Backend_Realtime_Workspace/infrastructure/redis/redis.service.js) — `initRedis()`, `setCache()`, `getCache()`, `checkRateLimit()` (sliding window), pub/sub, `disconnectRedis()`

### Heartbeat

> **See** [`Backend_Realtime_Workspace/infrastructure/redis/redis.service.js`](../Backend_Realtime_Workspace/infrastructure/redis/redis.service.js) — `initRedis()`, `setCache()`, `getCache()`, `checkRateLimit()` (sliding window), pub/sub, `disconnectRedis()`

### Batch Presence Query

> **See** [`Backend_Realtime_Workspace/infrastructure/redis/redis.service.js`](../Backend_Realtime_Workspace/infrastructure/redis/redis.service.js) — `initRedis()`, `setCache()`, `getCache()`, `checkRateLimit()` (sliding window), pub/sub, `disconnectRedis()`

---

## 4. Kafka Event Streaming

### Kafka vs RabbitMQ Responsibility Split

| Concern | Kafka | RabbitMQ |
|---------|-------|----------|
| Audit log (immutable, replayable) | ✅ | ❌ |
| Analytics event stream | ✅ | ❌ |
| AI RAG ingestion pipeline | ✅ | ❌ |
| Search re-indexing | ✅ | ❌ |
| Activity feeds | ✅ | ❌ |
| AI token streaming to WebSocket | ✅ | ❌ |
| Email sending (fire-and-forget) | ❌ | ✅ |
| Media processing | ❌ | ✅ |
| PDF generation | ❌ | ✅ |
| Push notifications (FCM) | ❌ | ✅ |
| Scheduled/delayed jobs | ❌ | ✅ |

### Kafka Topics

> **See** [`Backend_Realtime_Workspace/infrastructure/kafka/kafka-topics.js`](../Backend_Realtime_Workspace/infrastructure/kafka/kafka-topics.js) — Kafka topic name constants

### Event Envelope (Schema Contract)

Every Kafka event MUST include these fields — this is the schema contract:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Publishing Events

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Consumer Groups

```
Consumer Group: teamspot-audit       → Consumes all topics → writes to AuditLog
Consumer Group: teamspot-search      → Consumes task/issue/doc events → indexes to OpenSearch
Consumer Group: teamspot-rag         → Consumes RAG_INGEST → chunks + embeds → Qdrant
Consumer Group: teamspot-analytics   → Consumes all events → aggregates metrics
Consumer Group: teamspot-ai-stream   → Consumes AI_STREAM → pushes tokens to WebSocket
Consumer Group: teamspot-notifications → Consumes events → sends FCM/email
```

---

## 5. RabbitMQ Task Queues

### Queue Definitions

> **See** [`Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js`](../Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js) — `initRabbitMQ()`, `publishToQueue()`, `consumeQueue()` — with idempotency guard + DLQ

### Delayed Queue Pattern (Meeting Reminders)

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

---

## 6. LiveKit WebRTC Integration

LiveKit is the Selective Forwarding Unit (SFU) that handles all real-time audio/video.

### Architecture

```
Client (Flutter livekit_client SDK)
    │
    │  WebRTC (DTLS/SRTP)
    ▼
LiveKit SFU Server
    │
    │  REST API / Server SDK
    ▼
TeamSpot Backend (livekit-server-sdk)
```

### Room Token Generation

> **See** [`Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js`](../Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js) — `LiveKitService.createRoom()`, `.generateToken()` — WebRTC SFU room management

### Meeting Flow

```
1. POST /communication/rooms (host)
   → createRoom(meetingId) on LiveKit server
   → Store room metadata in MongoDB

2. POST /communication/rooms/token (each participant)
   → Validate: user is meeting attendee (permission check)
   → generateToken(roomName, userId, { canPublish: true })
   → Return { token, wsUrl }

3. Flutter client connects:
   → LiveKitRoom.connect(wsUrl, token)
   → Publishes audio/video tracks
   → Subscribes to other participants' tracks

4. Meeting end:
   → DELETE /communication/rooms/:name
   → LiveKit stops room, triggers recording finalization
   → Webhook → AI worker → transcription + summary ingestion
```

### VoIP Call State Machine

```
         ┌──────────────────────────────┐
         │         CALL STATES          │
         │                              │
initiating → ringing → active → ended  │
    │         │            │            │
    └──→ cancelled   rejected/missed    │
         │                              │
         └──────────────────────────────┘
```

State persisted in Redis (TTL 1 hour for active calls):

> **See** [`Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js`](../Backend_Realtime_Workspace/infrastructure/livekit/livekit.service.js) — `LiveKitService.createRoom()`, `.generateToken()` — WebRTC SFU room management

---

## 7. AI Token Streaming (SSE + Kafka)

AI responses are streamed token-by-token for perceived performance:

```
POST /ai/chat (SSE connection opened)
    │
    ▼
AgentExecutor.execute({ stream: true, res })
    │
    ▼
LangGraph StateGraph executes
    │
    ├── Tools execute (search, create_task, etc.)
    │
    ▼
streamGraphResponse(model, messages, res)
    │
    ├── Streams tokens via SSE: data: {"token": "Hello"}
    │
    ├── Publishes to Kafka: teamspot.ai.stream
    │      (for WebSocket fallback on mobile clients)
    │
    ▼
AI Kafka Consumer reads teamspot.ai.stream
    │
    ▼
emitToUser(userId, SocketEvents.AI_TOKEN_STREAM, { token })
```

SSE format:
```
Content-Type: text/event-stream
Cache-Control: no-cache
X-Accel-Buffering: no  ← nginx must disable buffering for AI endpoints

data: {"token": "Based"}
data: {"token": " on"}
data: {"token": " your"}
data: [DONE]
```
