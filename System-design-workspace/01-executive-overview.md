# 01 — Executive Overview
# TeamSpot: Enterprise Workspace Collaboration Platform

> **Classification**: Principal Architect Documentation  
> **Version**: 1.0.0  
> **Stack**: Node.js 20 · Express 5 · Flutter 3.5 · MongoDB · Redis · Kafka · RabbitMQ · Socket.IO · LiveKit · Firebase Auth · LangChain/LangGraph · OpenSearch · Qdrant · Cloudinary · Stripe  
> **Target Scale**: 1B+ DAU (enterprise-grade multi-tenant SaaS)

---

## 1. Elevator Pitch

TeamSpot is an enterprise-grade, AI-native workspace operating system that unifies project management, team communication, issue tracking, document intelligence, video collaboration, and autonomous AI agents into a single coherent platform. Think Jira + Slack + GitHub + Notion — but architecturally unified at the data layer, permission layer, and AI layer so that information flows intelligently between domains without copy-paste chaos or context loss.

---

## 2. What It Is

TeamSpot is **not** just another productivity tool. It is a programmable enterprise collaboration operating system designed for teams of 10 to 100,000+. The core thesis is that siloed tools (Jira for issues, Slack for chat, Google Docs for docs, Zoom for video) create organizational entropy — context is lost at every boundary, automation breaks at integrations, and AI cannot reason across fragmented data. TeamSpot collapses all these boundaries into one permission-consistent, event-driven, AI-searchable system.

### Core Platform Pillars

| Pillar | Description |
|--------|-------------|
| **Project Intelligence** | Projects, tasks, issues, tickets with full Gantt/Kanban/list views, milestones, SLA tracking |
| **Team Communication** | Slack-like channels, threaded messages, direct messages, voice/video rooms (LiveKit WebRTC) |
| **Document Knowledge Base** | Upload PDFs, DOCX, spreadsheets — auto-indexed into RAG pipeline for AI search |
| **AI Workspace Agent** | LangGraph ReAct agent with RAG retrieval, MCP tool calls, permission-aware context |
| **Organization IAM** | Multi-tenant RBAC + ABAC + ReBAC, invite-only onboarding, workspace isolation |
| **Observability** | Prometheus + OpenTelemetry + Pino structured logs + Sentry + Grafana health checks |
| **Billing & Plans** | Stripe subscriptions, per-seat pricing, usage quotas per plan tier |
| **Workflow Automation** | Trigger → Condition → Action automation engine (Zapier-style internal) |

---

## 3. Why It Exists — The Problem Space

Modern enterprises pay for 12–20 different SaaS tools that never truly talk to each other:

- A developer creates a GitHub issue that never maps to a Jira ticket
- A Slack conversation contains the key decision that nobody can find 6 months later
- A Zoom meeting produces notes in Google Docs that nobody links back to the project
- The AI assistant cannot answer "What is the status of Project Alpha?" because the data lives in three siloed tools

TeamSpot eliminates these integration costs by being the **single source of truth** for organizational work — while exposing a public API and webhook system for teams that still want to integrate external tools.

---

## 4. Who The Users Are

### Primary Users
| Role | Usage Pattern |
|------|---------------|
| **Developers** | Issues, tasks, PR-linked tickets, code integration, AI code context |
| **Project Managers** | Projects, timelines, Gantt charts, team capacity, reporting |
| **Team Leads / Managers** | Team analytics, permissions, approval workflows, AI summaries |
| **Executives** | Dashboard analytics, org health, billing, audit logs |
| **Support Agents** | Ticket queues, SLA tracking, knowledge base search |
| **New Employees** | Onboarding via invite code, workspace access, document discovery |

### Secondary Users
- **Enterprise Admins**: Tenant management, security policies, SCIM provisioning, impersonation
- **API Consumers**: Developers building integrations via public API / webhook subscriptions

---

## 5. Business Goals

1. **Replace 5–10 tools** per enterprise team, generating immediate ROI on consolidation
2. **AI productivity multiplier**: Every team member has an AI agent that knows all workspace context
3. **Enterprise sales motion**: Security, compliance (GDPR, SOC2-ready), SSO, and audit trails required for enterprise procurement
4. **Platform extensibility**: Integration ecosystem (GitHub, Slack, Jira import, Google Drive, Zoom) to ease migration and coexistence
5. **Usage-based growth**: More usage → more AI queries → more value → higher plan conversion

---

## 6. Engineering Goals

1. **Correctness over speed** — permissions must be correct at every layer (HTTP, WebSocket, RAG retrieval, AI tool execution)
2. **Eventual consistency tolerance** — system must degrade gracefully when Kafka/Redis/RabbitMQ are unavailable; no data loss
3. **Sub-200ms API p95** for all non-AI endpoints
4. **AI agent latency** — first token < 1s via SSE streaming, full response < 8s
5. **Zero-downtime deploys** via Kubernetes rolling updates
6. **Observable by default** — every request has a correlation ID, every event has a traceId, every AI call has token accounting

---

## 7. Technical Summary

```
Flutter App (iOS/Android/Web/Desktop)
         │
         ▼
    Firebase Auth ──→ ID Token
         │
         ▼
   Nginx Reverse Proxy (rate limiting, WebSocket upgrade)
         │
         ▼
   Express 5 Monolith (Node.js 20, ESM)
   ├── 30+ Feature Modules (auto-registered)
   ├── WebSocket Gateway (Socket.IO + Redis adapter)
   ├── AI Agent (LangGraph ReAct + RAG + MCP)
   ├── Background Workers (RabbitMQ consumers)
   └── Event Bus (Kafka + DomainEventBus)
         │
    ┌────┼────────────────────────┐
    ▼    ▼                        ▼
MongoDB  Redis               Kafka / RabbitMQ
(primary (cache/presence/     (streaming/queues)
  store)  pub-sub/sessions)
         │
    ┌────┼──────────────────────┐
    ▼    ▼                      ▼
Cloudinary  LiveKit SFU     Qdrant Vector DB
(media)    (WebRTC rooms)   (RAG embeddings)
                                │
                            OpenSearch
                          (full-text search)
```

---

## 8. Infrastructure Summary

| Layer | Technology |
|-------|-----------|
| Containerization | Docker multi-stage (node:20-alpine) |
| Orchestration | Kubernetes (3 replicas, RollingUpdate) |
| IaC | Terraform (VPC, EKS, RDS-equivalent, Redis) |
| CDN / Edge | Cloudflare (WAF + CDN + R2 storage option) |
| CI/CD | GitHub Actions (lint → test → build → deploy) |
| Secrets | K8s Secrets (env injection) → Vault (future) |
| Monitoring | Prometheus + Grafana + Sentry + OpenTelemetry |

---

## 9. Market Positioning

| Competitor | TeamSpot Advantage |
|------------|-------------------|
| Jira | AI-native, integrated chat/video, no plugin hell |
| Slack | Issue/task tracking built in, document AI search |
| Notion | Structured project management + real-time video |
| Linear | Enterprise multi-tenant, full communication layer |
| Monday.com | AI agent with RAG + permission-aware document search |
| Microsoft Teams | Open API, no Microsoft lock-in, better developer UX |

---

## 10. Long-Term Vision

TeamSpot evolves through three phases:

**Phase 1 — Unified Workspace (Current)**  
Replace fragmented tooling with a coherent, AI-searchable, permission-consistent workspace platform.

**Phase 2 — Enterprise Platform**  
Public API, marketplace for integrations, SCIM/SAML enterprise SSO, government compliance (HIPAA, FedRAMP), multi-region active-active deployment.

**Phase 3 — Autonomous Organization**  
AI agents that proactively surface risks (stalled projects, budget overruns, burnout signals), draft proposals, generate reports, schedule meetings, and route work items — with human approval gates at critical decision points. The workspace becomes self-managing for routine coordination tasks.

---

## 11. Key Engineering Decisions & Rationale

### Modular Monolith over Microservices
At current scale, a modular monolith with strict domain boundaries gives developer velocity without the operational overhead of distributed deployments. All modules share a process but enforce domain boundaries through interfaces. Kafka provides the event bus abstraction that enables selective service extraction later without rewriting consumers.

### Firebase Auth Only for Social/SSO — Not for Business Logic
Firebase handles the authentication credential lifecycle (Google OAuth, GitHub OAuth, 2FA). The backend issues its own JWT for session continuity and rate-limit attribution. Business logic (org membership, workspace access, role checks) lives entirely in MongoDB. This avoids Firebase lock-in and keeps IAM logic in the domain model.

### Kafka for Event Streaming, RabbitMQ for Task Queues
These are not interchangeable. Kafka is used for ordered event logs (audit trails, analytics, AI indexing, activity feeds) where replay and consumer groups are required. RabbitMQ is used for fire-and-forget task queues (email sending, media processing, PDF generation) where exactly-once delivery and dead-letter queues matter more than replay.

### Qdrant for Vector Storage, OpenSearch for Full-Text
AI RAG retrieval uses Qdrant (vector similarity + metadata filtering). General workspace search (issues, tasks, documents by keyword) uses OpenSearch. MongoDB text search is insufficient at scale — OpenSearch provides typo tolerance, relevance scoring, and faceted filtering. Both are fed via async Kafka consumers, keeping indexing off the request path.
