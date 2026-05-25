# 09 — Infrastructure & DevOps
# TeamSpot: Containerization, Kubernetes, CI/CD, IaC & Production Topology

---

## 1. Infrastructure Philosophy

TeamSpot's infrastructure is designed with three principles:
1. **Everything is code** — all infrastructure defined in Terraform and K8s manifests
2. **Environments are identical** — dev/staging/production use the same Docker image, only env vars differ
3. **Deploy without fear** — CI/CD catches issues before production; K8s rolling updates ensure zero downtime

---

## 2. Docker: Multi-Stage Production Build

> **See** [`Backend_Realtime_Workspace/config/env.config.js`](../Backend_Realtime_Workspace/config/env.config.js) — Environment config — all env var declarations with Joi validation

**Why multi-stage?**
- Final image contains zero build tools (no npm, no git)
- Image size: ~120MB vs ~500MB single-stage
- Attack surface reduced: no shell tools in production container
- `--only=production` excludes devDependencies (eslint, vitest, nodemon)

---

## 3. Docker Compose: Local Development Stack

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

---

## 4. Kubernetes Architecture

### Namespace Strategy
> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

### Deployment (3 replicas, RollingUpdate)
> **See** [`Backend_Realtime_Workspace/k8s/deployment.yaml`](../Backend_Realtime_Workspace/k8s/deployment.yaml) — Kubernetes Deployment — 3 replicas, RollingUpdate, pod anti-affinity, resource limits

### Horizontal Pod Autoscaler
> **See** [`Backend_Realtime_Workspace/agent/knowledge/rag-pipeline.js`](../Backend_Realtime_Workspace/agent/knowledge/rag-pipeline.js) — `RagPipeline` — document chunking → embedding → Qdrant upsert → retrieval

### ConfigMap vs Secrets Split
```
ConfigMap (non-sensitive, version-controlled):
  NODE_ENV, PORT, LOG_LEVEL, API_VERSION, KAFKA_BROKERS,
  PROMETHEUS_METRICS_ENABLED, OTEL_EXPORTER_OTLP_ENDPOINT

Secrets (sensitive, never in git):
  MONGO_URI, JWT_SECRET, ENCRYPTION_KEY, FIREBASE_SERVICE_ACCOUNT,
  REDIS_PASSWORD, STRIPE_SECRET_KEY, OPENAI_API_KEY, SENTRY_DSN,
  LIVEKIT_API_SECRET, CLOUDINARY_API_SECRET
```

---

## 5. CI/CD Pipeline

### GitHub Actions: Pull Request Flow (ci.yml)

> **See** [`Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js`](../Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js) — `StripeService` — subscription plans, checkout sessions, webhook handlers

### GitHub Actions: Production Deploy (cd.yml)

> **See** [`Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js`](../Backend_Realtime_Workspace/infrastructure/billing/stripe.service.js) — `StripeService` — subscription plans, checkout sessions, webhook handlers

### Pre-commit Hooks (Husky + lint-staged)

```
pre-commit:
  lint-staged:
    "*.js"       → eslint --fix + prettier --write
    "*.{json,md,yaml}" → prettier --write

commit-msg:
  commitlint → enforce Conventional Commits:
    feat / fix / docs / style / refactor / perf / test / build / ci / chore / revert
```

---

## 6. Terraform Infrastructure-as-Code

### Provider Configuration
> **See** [`Backend_Realtime_Workspace/terraform`](../Backend_Realtime_Workspace/terraform) — Terraform IaC — `main.tf`, `database.tf`, `redis.tf`, `cloudflare.tf`, `variables.tf`

### Core Infrastructure Modules
```
terraform/
├── main.tf          # VPC, EKS cluster, managed node groups (t3.xlarge)
├── database.tf      # MongoDB Atlas cluster via mongodbatlas provider
├── redis.tf         # ElastiCache Redis cluster (cluster mode enabled)
├── cloudflare.tf    # DNS, CDN rules, WAF policies, R2 bucket
├── variables.tf     # Input variables (env, region, cluster size)
├── outputs.tf       # EKS endpoint, RDS URL, Redis endpoint
└── providers.tf     # Provider versions + S3 remote state
```

### Key Infrastructure Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Kubernetes | AWS EKS | Managed control plane, easy node scaling |
| Database | MongoDB Atlas | Managed ops, built-in replica set, Atlas Search |
| Redis | AWS ElastiCache | Managed Redis Cluster, automated failover |
| CDN | Cloudflare | WAF + CDN + R2 storage + Workers at edge |
| Container Registry | GitHub Container Registry (GHCR) | Free with GitHub, integrated with Actions |
| Secrets | K8s Secrets → Vault (future) | Simple now, migrate to Vault for KMS rotation |

---

## 7. Nginx Configuration

### Rate Limiting Zones
```nginx
# nginx/nginx.conf
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=upload:10m rate=5r/s;

upstream teamspot_api {
  server api:5000;
  keepalive 64;  # persistent connections to Node.js
}
```

### WebSocket & SSE Configuration
```nginx
# nginx/default.conf
location /socket.io/ {
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_read_timeout 3600s;    # keep WebSocket alive
}

location /api/v1/ai/chat {
  # AI SSE (Server-Sent Events) — disable buffering
  proxy_buffering off;
  proxy_cache off;
  proxy_read_timeout 120s;
  proxy_set_header X-Accel-Buffering no;
  add_header X-Accel-Buffering no;
}
```

---

## 8. Health Check Architecture

> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

### Health Check Response
> **See** [`Backend_Realtime_Workspace/infrastructure/database/mongoose.js`](../Backend_Realtime_Workspace/infrastructure/database/mongoose.js) — `initDB()` — Mongoose connection with replica-set awareness and retry

---

## 9. Environment Promotion Strategy

```
Developer Laptop (docker-compose)
        ↓  git push feature/branch
Pull Request (GitHub Actions CI)
        ↓  eslint + tests + audit pass
Staging (auto-deploy on PR merge to develop)
        ↓  manual QA + automated smoke tests
Production (auto-deploy on merge to main)
        ↓  K8s rolling update, 0-downtime
```

Environment variables are **never** in source control. The `.env.example` documents all required keys; actual values are in K8s Secrets (production) and a shared `.env` file (development, distributed via 1Password / Vault).
