# 07 — Security Architecture
# TeamSpot: IAM, Threat Model, OWASP, Encryption & Zero Trust

---

## 1. Security Philosophy: Defense in Depth

TeamSpot applies security controls at every layer rather than relying on any single perimeter. This is Defense in Depth (DiD), the same model used by Google, AWS, and enterprise security frameworks.

```
Layer 1: Network (Nginx WAF, rate limiting, DDoS protection)
Layer 2: Transport (TLS 1.3, HSTS, certificate pinning)
Layer 3: Application (Helmet, CORS, CSP, XSS protection)
Layer 4: Authentication (Firebase + JWT, 2FA, session management)
Layer 5: Authorization (RBAC + ABAC + ReBAC, permission engine)
Layer 6: Data (tenant isolation, field-level encryption, GDPR)
Layer 7: AI (prompt injection guard, permission-aware RAG)
Layer 8: Audit (immutable logs, anomaly detection)
```

---

## 2. Identity & Access Management (IAM)

### Authentication Architecture

```
Firebase Auth (Credential Layer)
    │
    │  Handles: Social OAuth (Google, GitHub), 2FA flows, password reset
    │  Does NOT handle: business logic, org membership, workspace permissions
    │
    ▼
Backend JWT (Session Layer)
    │
    │  Handles: API authorization, session tracking, rate-limit attribution
    │  Format: HS256 signed JWT { userId, tenantId, sessionId, iat, exp }
    │  Expiry: 7 days access + 30 day refresh
    │
    ▼
Permission Engine (Authorization Layer)
    │
    │  Handles: RBAC + ABAC + ReBAC, resource-level permissions
```

### Permission Engine: RBAC + ABAC + ReBAC

> **See** [`Backend_Realtime_Workspace/core/auth/permission-engine.js`](../Backend_Realtime_Workspace/core/auth/permission-engine.js) — `evaluatePermission()` — RBAC + ABAC + ReBAC (Zanzibar-inspired) evaluation

### 2FA Implementation

TeamSpot supports three 2FA mechanisms:

| Method | Implementation | Use Case |
|--------|----------------|----------|
| TOTP | speakeasy TOTP (RFC 6238) | Google Authenticator / Authy |
| Email OTP | 6-digit code, 10min TTL, Redis | Fallback for no authenticator app |
| SMS OTP | 6-digit code via SMTP/SMS gateway | Recovery + enterprise requirement |

TOTP secrets are encrypted at rest using AES-256-GCM before storage (`core/crypto/encryption.service.js`).

---

## 3. OWASP Top 10 Mitigations

### A01 — Broken Access Control

**Mitigation**:
- Every API endpoint has explicit `requirePermission()` middleware
- Tenant isolation enforced at query level (always include `tenantId` filter)
- ReBAC checks prevent cross-workspace data access
- Unit tests validate permission enforcement for each endpoint

> **See** [`Backend_Realtime_Workspace/core/auth/permission.middleware.js`](../Backend_Realtime_Workspace/core/auth/permission.middleware.js) — `requirePermission()` middleware — checks role permissions per route

### A02 — Cryptographic Failures

**Mitigation**:
- TLS 1.3 enforced; TLS 1.0/1.1 disabled at Nginx layer
- HSTS with `max-age=31536000; includeSubDomains; preload`
- TOTP secrets: AES-256-GCM encrypted before MongoDB storage
- Passwords: bcryptjs (cost factor 12) — never stored plaintext
- JWT: HS256 signed with 256-bit secret from env
- Sensitive env vars never logged (redacted in logger)

> **See** [`Backend_Realtime_Workspace/config/env.config.js`](../Backend_Realtime_Workspace/config/env.config.js) — Environment config — all env var declarations with Joi validation

### A03 — Injection

**Mitigation**:
- MongoDB queries use Mongoose ORM — never string concatenation
- Input validated with express-validator + zod schemas before any DB operation
- HTML content sanitized via `xss-clean` middleware before storage
- AI inputs screened by PromptGuard before LLM invocation
- No raw shell execution in codebase

### A04 — Insecure Design

**Mitigation**:
- Invite-only org onboarding prevents unauthorized access
- Rate limiting per endpoint type (auth: 20/15min; AI: 30/min)
- Soft deletes prevent data recovery abuse
- Audit logs capture every state change

### A05 — Security Misconfiguration

**Mitigation**:
- Helmet.js sets all security headers automatically
- CORS explicitly allowlist production origins only
- Development configuration is separate from production
- No stack traces in production API responses
- Docker runs as non-root user (UID 1001)

> **See** [`Backend_Realtime_Workspace/infrastructure/storage/cloudinary.service.js`](../Backend_Realtime_Workspace/infrastructure/storage/cloudinary.service.js) — `CloudinaryService.upload()`, `.delete()`, `.getVariant()` — CDN media management

### A06 — Vulnerable & Outdated Components

**Mitigation**:
- GitHub Actions CI runs `npm audit` on every PR
- TruffleHog secret scanning on every commit
- Dependabot configured for automatic security PRs
- `.github/workflows/ci.yml` blocks merge if critical vulnerabilities found

### A07 — Identification and Authentication Failures

**Mitigation**:
- Auth endpoints rate limited to 20 req/15min (`authLimiter`)
- Account lockout after 5 failed login attempts (Redis-backed counter)
- Session invalidation on password change (all tokens revoked)
- Firebase token verification on every authenticated request (no caching of verification)
- JWT rotation: access token 7d + refresh token 30d

### A08 — Software and Data Integrity Failures

**Mitigation**:
- Webhook payloads signed with HMAC-SHA256
- Kafka messages include `eventId` for consumer idempotency
- Docker images from official node:20-alpine (minimal attack surface)
- CI pipeline enforces signed commits (commitlint)

### A09 — Security Logging and Monitoring Failures

**Mitigation**:
- Every request logged with `requestId`, `userId`, `tenantId`, `path`, `statusCode`, `durationMs`
- Failed auth attempts logged to dedicated security audit channel
- Sentry captures all unhandled exceptions with context
- Prometheus alerts on anomalous error rates, latency spikes
- Audit log is append-only and cannot be modified via API

### A10 — Server-Side Request Forgery (SSRF)

**Mitigation**:
- Webhook URLs validated against allowlist before delivery
- Integration OAuth callbacks go through backend proxy (not user-supplied URLs)
- No user-controlled URL fetching without validation

---

## 4. AI Security

### Prompt Injection Defense

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

### Data Exfiltration Prevention

- RAG retrieval enforces ACL at the vector DB layer (cannot be bypassed by prompt)
- Tool execution is sandboxed — tools can only access tenant-scoped data
- System prompt includes explicit instruction: never reveal other users' data
- Output scanning (future): detect if AI response contains patterns matching sensitive data

### AI Permission Enforcement

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 5. Secret Management

```
Development: .env file (gitignored, never committed)
Staging:     .env.staging (encrypted at rest on server)
Production:  Kubernetes Secrets → mounted as env vars
Future:      HashiCorp Vault for dynamic secrets + rotation
```

Secret categories and their storage:
```
DB credentials     → K8s Secret (mounted env)
JWT secrets        → K8s Secret
Firebase SA key    → K8s Secret (JSON file mount)
AI API keys        → K8s Secret
Stripe keys        → K8s Secret
Cloudinary creds   → K8s Secret
LiveKit keys       → K8s Secret
```

**Secret rotation policy**:
- JWT_SECRET: Rotate every 90 days (require all sessions to re-auth)
- ENCRYPTION_KEY: Rotate yearly with data re-encryption job
- API keys: Rotate on personnel departure or suspected compromise

---

## 6. Infrastructure Security

### Container Security

> **See** [`Backend_Realtime_Workspace/Dockerfile`](../Backend_Realtime_Workspace/Dockerfile) — Multi-stage Dockerfile — builder → production (node:20-alpine)

### Kubernetes Security

> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

### Nginx Security

```nginx
# nginx/default.conf
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=2r/s;

# Security headers at nginx level (redundant layer with Helmet)
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header Referrer-Policy strict-origin-when-cross-origin;

# Prevent nginx version disclosure
server_tokens off;
```

---

## 7. GDPR & Data Privacy

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`
