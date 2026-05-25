# 04 — API Architecture
# TeamSpot: REST Design, Versioning, Auth, Pagination & Standards

---

## 1. API Philosophy

TeamSpot exposes a versioned REST API. The design decisions are:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Protocol | REST over HTTPS | Universal compatibility; simpler than GraphQL for mobile; gRPC adds complexity without benefit at this scale |
| Format | JSON | Universal; Dio/Axios parse natively; structured errors |
| Versioning | URL prefix `/api/v1/` | Visible, explicit, easy to route at nginx layer |
| Authentication | Firebase ID Token (Bearer) | Delegates credential lifecycle to Firebase; backend verifies without storing passwords |
| Pagination | Cursor + Offset hybrid | Cursor for feeds; offset for management views |
| Error format | `{ success, error: { code, message, details } }` | Consistent across all endpoints; machine-parseable error codes |

---

## 2. URL Structure

```
Base URL: https://api.teamspot.app

Public API:
  /api/v1/{resource}
  /api/v1/{resource}/{id}
  /api/v1/{resource}/{id}/{sub-resource}

Health:
  /health          → liveness probe (always 200 if process running)
  /health/ready    → readiness probe (200 if all infra connected)
  /health/detailed → detailed health per dependency

Observability:
  /metrics         → Prometheus scrape endpoint

WebSocket:
  wss://api.teamspot.app  → Socket.IO upgrade
```

---

## 3. Full Endpoint Reference

### Authentication  `/api/v1/auth`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/auth/social` | Social sign-in (Firebase ID token) | None |
| POST | `/auth/register` | Email/password registration | None |
| POST | `/auth/login` | Email/password login | None |
| POST | `/auth/logout` | Invalidate current session | Required |
| POST | `/auth/logout-all` | Invalidate all sessions | Required |
| POST | `/auth/refresh` | Refresh backend JWT | None (refresh token) |
| POST | `/auth/forgot-password` | Send reset email | None |
| POST | `/auth/reset-password` | Apply password reset | None |
| POST | `/auth/change-password` | Change password (authenticated) | Required |
| POST | `/auth/verify-email` | Verify email via token | None |
| GET | `/auth/sessions` | List active sessions | Required |
| DELETE | `/auth/sessions/:id` | Revoke specific session | Required |
| GET | `/auth/2fa/status` | 2FA configuration status | Required |
| POST | `/auth/2fa/totp/setup` | Get TOTP QR code | Required |
| POST | `/auth/2fa/totp/confirm` | Confirm TOTP setup | Required |
| POST | `/auth/2fa/totp/verify` | Verify TOTP code | Required |
| POST | `/auth/2fa/totp/disable` | Disable TOTP | Required |
| POST | `/auth/2fa/email/send` | Send OTP via email | Required |
| POST | `/auth/2fa/email/verify` | Verify email OTP | Required |
| POST | `/auth/2fa/sms/send` | Send OTP via SMS | Required |
| POST | `/auth/2fa/sms/verify` | Verify SMS OTP | Required |

### Users  `/api/v1/users`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/users/me` | Current user profile | Required |
| PATCH | `/users/me` | Update profile | Required |
| DELETE | `/users/me` | Delete account (GDPR) | Required |
| POST | `/users/me/upload-picture` | Upload avatar | Required |
| POST | `/users/me/invite-code/regenerate` | Regenerate invite code | Required |
| GET | `/users` | List users (admin/workspace context) | Required |
| GET | `/users/search` | Search users | Required |
| GET | `/users/:id` | Get user profile | Required |

### Organizations  `/api/v1/organizations`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/organizations` | Create organization | Required |
| GET | `/organizations` | List user's organizations | Required |
| GET | `/organizations/:id` | Get organization | Required |
| PATCH | `/organizations/:id` | Update organization | Admin |
| DELETE | `/organizations/:id` | Delete organization | Owner |
| POST | `/organizations/:id/invite` | Create invite link | Admin |
| GET | `/organizations/:id/members` | List members | Admin |
| DELETE | `/organizations/:orgId/members/:userId` | Remove member | Admin |
| PATCH | `/organizations/:id/settings` | Update settings | Admin |

### Workspaces  `/api/v1/workspaces`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/workspaces` | Create workspace | Required |
| GET | `/workspaces` | List org workspaces | Required |
| GET | `/workspaces/:id` | Get workspace | Member |
| PATCH | `/workspaces/:id` | Update workspace | Admin |
| DELETE | `/workspaces/:id` | Archive workspace | Owner |
| GET | `/workspaces/:id/members` | List workspace members | Member |
| POST | `/workspaces/:id/invite` | Invite to workspace | Admin |
| DELETE | `/workspaces/:workspaceId/members/:userId` | Remove member | Admin |

### Projects  `/api/v1/projects`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/projects` | Create project | Member |
| GET | `/projects` | List workspace projects | Member |
| GET | `/projects/generate-key` | Generate project key | Member |
| GET | `/projects/:id` | Get project detail | Member |
| PATCH | `/projects/:id` | Update project | Project admin |
| DELETE | `/projects/:id` | Archive project | Project admin |
| POST | `/projects/:id/star` | Star/unstar project | Member |
| POST | `/projects/:id/archive` | Archive project | Admin |
| GET | `/projects/:id/timeline` | Project timeline | Member |
| GET | `/projects/:id/members` | Project collaborators | Member |
| POST | `/projects/:id/members` | Add collaborator | Admin |
| DELETE | `/projects/:id/members/:userId` | Remove collaborator | Admin |
| POST | `/projects/:id/attachments` | Upload attachment | Member |
| DELETE | `/projects/:id/attachments/:attachmentId` | Remove attachment | Admin |

### Tasks  `/api/v1/tasks`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/tasks` | Create task | Member |
| GET | `/tasks` | List tasks (filterable) | Member |
| GET | `/tasks/:id` | Get task detail | Member |
| PATCH | `/tasks/:id` | Update task | Assignee/Admin |
| DELETE | `/tasks/:id` | Archive task | Admin |
| POST | `/tasks/:id/comments` | Add comment | Member |
| PATCH | `/tasks/:id/checklist` | Update checklist | Member |
| POST | `/tasks/:id/attachments` | Upload attachment | Member |

### Issues  `/api/v1/issues`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/issues` | Create issue |
| GET | `/issues` | List issues |
| GET | `/issues/:id` | Get issue detail |
| PATCH | `/issues/:id` | Update issue |
| DELETE | `/issues/:id` | Close/archive issue |
| POST | `/issues/:id/comments` | Comment |
| POST | `/issues/:id/link` | Link to task/issue |

### Tickets  `/api/v1/tickets`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/tickets` | Submit ticket |
| GET | `/tickets` | List tickets (queue) |
| GET | `/tickets/:id` | Get ticket detail |
| PATCH | `/tickets/:id` | Update ticket / change status |
| POST | `/tickets/:id/comments` | Add note |
| POST | `/tickets/:id/escalate` | Escalate ticket |

### Channels  `/api/v1/channels`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/channels` | Create channel |
| GET | `/channels` | List channels |
| GET | `/channels/:id` | Get channel |
| PATCH | `/channels/:id` | Update channel |
| DELETE | `/channels/:id` | Archive channel |
| GET | `/channels/:id/members` | List members |
| POST | `/channels/:id/members` | Add member |
| DELETE | `/channels/:channelId/members/:memberId` | Remove member |
| GET | `/channels/:id/messages` | Get messages (paginated) |

### Communication  `/api/v1/communication`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/communication/rooms/token` | Get LiveKit room token |
| POST | `/communication/rooms` | Create LiveKit room |
| GET | `/communication/rooms` | List active rooms |
| DELETE | `/communication/rooms/:name` | Delete room |
| GET | `/communication/rooms/:name/participants` | List participants |
| POST | `/communication/rooms/:name/remove-participant` | Kick participant |
| POST | `/communication/calls/initiate` | Initiate VoIP call |
| PUT | `/communication/calls/:id/accept` | Accept call |
| PUT | `/communication/calls/:id/end` | End call |
| PUT | `/communication/calls/:id/reject` | Reject call |
| GET | `/communication/calls/history` | Call history |
| POST | `/communication/messages` | Send DM |
| GET | `/communication/messages` | Get DMs |
| DELETE | `/communication/messages/:id` | Delete DM |

### AI  `/api/v1/ai`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/ai/chat` | Chat with AI (SSE stream) |
| GET | `/ai/conversations` | List conversations |
| GET | `/ai/conversations/:id` | Get conversation |
| DELETE | `/ai/conversations/:id` | Delete conversation |
| POST | `/ai/rag/query` | Semantic search |
| POST | `/ai/rag/ingest` | Ingest document into RAG |
| GET | `/ai/rag/status` | RAG indexing status |
| GET | `/ai/tools` | List available tools |
| POST | `/ai/tools/:name/execute` | Execute AI tool |
| POST | `/ai/summarize` | Summarize content |

### Meetings  `/api/v1/meetings`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/meetings` | Schedule meeting |
| GET | `/meetings` | List meetings |
| GET | `/meetings/:id` | Meeting detail |
| PATCH | `/meetings/:id` | Update meeting |
| DELETE | `/meetings/:id` | Cancel meeting |
| POST | `/meetings/:id/join` | Join meeting |
| POST | `/meetings/:id/rsvp` | RSVP |

---

## 4. Request/Response Standards

### Standard Success Response

> **See** [`Backend_Realtime_Workspace/core/base/base.repository.js`](../Backend_Realtime_Workspace/core/base/base.repository.js) — `BaseRepository` — `findById()`, `paginate()`, `cursorPaginate()`, multi-tenant `_scopeFilter()`

### Standard Error Response

> **See** [`Backend_Realtime_Workspace/`](../Backend_Realtime_Workspace/) — backend source

---

## 5. Authentication Flow

```
Client                     Firebase               Backend
  │                            │                      │
  │──── Social Sign-In ────→   │                      │
  │                            │                      │
  │←─── Firebase ID Token ─────│                      │
  │                            │                      │
  │──── POST /auth/social ─────────────────────────→  │
  │     { idToken, inviteCode? }                       │
  │                            │                      │
  │                            │←── Verify Token ─────│
  │                            │──→ {uid, email} ──→   │
  │                            │                      │
  │                            │                Lookup/Create User
  │                            │                Validate invite
  │                            │                Issue JWT
  │                            │                      │
  │←─── { accessToken, refreshToken, user } ──────────│
  │                                                    │
  │──── API Request ──────────────────────────────────→│
  │     Authorization: Bearer <accessToken>            │
  │                                                    │
  │                                    firebaseAuthMiddleware:
  │                                    1. Verify JWT (local)
  │                                    2. Attach req.user
  │                                    3. Next()
  │                                                    │
  │←─── Response ─────────────────────────────────────│
```

---

## 6. Rate Limiting

Rate limits are applied per IP and per authenticated user:

> **See** [`Backend_Realtime_Workspace/config/constants.js`](../Backend_Realtime_Workspace/config/constants.js) — All app constants — `HttpStatus`, `ErrorCodes` (E1xxx–E9xxx), `WorkspaceConfig`, `SocketEvents`, `KafkaTopics`

Rate limit exceeded returns `429 Too Many Requests` with `Retry-After` header.

---

## 7. API Versioning Strategy

```
Current: /api/v1/...
Next:     /api/v2/...  (when breaking changes required)

Rules:
- v1 stays supported for minimum 12 months after v2 launch
- Additive changes (new fields) are non-breaking — applied to existing version
- Structural changes (rename, remove, type change) require new version
- Deprecation announced in X-API-Deprecated: true response header
- Migration guide published with v2 docs
```

---

## 8. Idempotency

Long-running or mutation operations accept an `Idempotency-Key` header:

```
POST /tasks
Idempotency-Key: <uuid>

If duplicate key detected within 24h window:
→ Return cached original response
→ Do NOT create a second task
```

This prevents duplicate submissions when:
- Mobile client retries on network timeout
- Worker retries a Kafka message
- Client double-submits on poor connection

---

## 9. Webhook System

TeamSpot publishes webhooks for external integrations:

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

Security: Each webhook endpoint has a secret. Payloads are signed with HMAC-SHA256. Receivers must verify the signature before processing.

Retry policy: Exponential backoff, max 3 retries, dead-letter after failure.
