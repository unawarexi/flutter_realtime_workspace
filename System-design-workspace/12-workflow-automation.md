# 12 — Workflow Automation Engine
# TeamSpot: Trigger → Condition → Action Automation & Event-Driven Workflows

---

## 1. Automation Philosophy

TeamSpot's workflow engine allows teams to automate routine coordination without writing code. The model is:

```
WHEN <trigger event occurs>
  IF <conditions are met>
  THEN <execute actions>
```

Examples:
- WHEN `issue.status` changes to `Done` → THEN notify manager AND post to channel
- WHEN `task.dueDate` is 24 hours away AND `task.status != Completed` → THEN send reminder
- WHEN new member joins workspace → THEN assign onboarding task template
- WHEN `ticket.priority == Critical` AND no response in 2 hours → THEN escalate to admin

---

## 2. Workflow Data Model

> **See** [`Backend_Realtime_Workspace/core/auth/tenant.middleware.js`](../Backend_Realtime_Workspace/core/auth/tenant.middleware.js) — Multi-tenant isolation middleware — injects `tenantId` on every request

---

## 3. Workflow Execution Architecture

```
Domain Event Fired (e.g., task.status.changed)
          │
          ▼
Kafka topic: teamspot.workflow.trigger
          │
          ▼
workflow.worker.js (RabbitMQ consumer)
          │
          ▼
WorkflowService.evaluate(event)
  ├── Query active workflows matching trigger type + event name
  ├── For each matching workflow:
  │   ├── Evaluate conditions against event payload
  │   └── If all conditions pass → queue actions
          │
          ▼
Action Execution Queue (RabbitMQ delayed queue)
  ├── send_notification → FCM + in-app notification
  ├── send_email        → mailer.service.js
  ├── create_task       → TaskService.create()
  ├── post_channel_msg  → ChannelService.postMessage()
  ├── trigger_webhook   → HTTP POST to external URL
  └── run_ai_summary    → AgentExecutor.execute()
```

### Worker Implementation

> **See** [`Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js`](../Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js) — `initRabbitMQ()`, `publishToQueue()`, `consumeQueue()` — with idempotency guard + DLQ

---

## 4. Condition Evaluation Engine

> **See** [`Backend_Realtime_Workspace/core/events/event-bus.js`](../Backend_Realtime_Workspace/core/events/event-bus.js) — `DomainEventBus` — in-process typed event bus

---

## 5. Scheduled Workflow Triggers (Cron)

> **See** [`Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js`](../Backend_Realtime_Workspace/infrastructure/rabbitmq/rabbitmq.service.js) — `initRabbitMQ()`, `publishToQueue()`, `consumeQueue()` — with idempotency guard + DLQ

---

## 6. Built-in Automation Templates

Pre-built templates users can activate with one click:

| Template | Trigger | Condition | Action |
|----------|---------|-----------|--------|
| Task Overdue Alert | `schedule: 0 9 * * *` | task.dueDate < now AND task.status != Done | send_notification to assignee |
| New Issue Assigned | `event: issue.assigned` | always | send_notification + send_email |
| Project Complete | `event: project.completed` | always | post_channel_message + run_ai_summary |
| High-Priority Ticket | `event: ticket.created` | ticket.priority == Critical | escalate_ticket + send_notification |
| Onboarding Welcome | `event: workspace.member.joined` | always | create_task (from template) + send_email |
| SLA Breach Warning | `schedule: */30 * * * *` | ticket.sla_deadline < 2h AND status != Resolved | escalate_ticket + send_email |

---

## 7. Webhook Trigger & Action

### Incoming Webhooks (external → TeamSpot workflow)

```
POST /api/v1/workflows/webhook/:workflowId
  Authorization: Bearer <webhook-secret>
  Body: { event: 'deploy.success', repo: 'frontend', sha: 'abc123' }

→ WorkflowService.triggerWebhook(workflowId, payload)
→ Evaluate conditions → Execute actions
```

### Outgoing Webhooks (TeamSpot → external service)

> **See** [`Backend_Realtime_Workspace/core/events/event-bus.js`](../Backend_Realtime_Workspace/core/events/event-bus.js) — `DomainEventBus` — in-process typed event bus

Webhook deliveries are logged, retried on failure (3 attempts with backoff), and viewable in the admin panel for debugging.
