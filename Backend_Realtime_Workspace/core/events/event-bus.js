// ============================================================================
// TeamSpot — Internal Event Bus
// In-process pub/sub for domain events within the modular monolith
// ============================================================================

import { EventEmitter } from "events";
import { createLogger } from "../../observability/logger.js";
import { randomUUID } from "crypto";

const log = createLogger("EventBus");

class DomainEventBus extends EventEmitter {
  constructor() {
    super();
    this.setMaxListeners(100);
    this._handlers = new Map();
    this._processedEvents = new Set();
  }

  publish(eventName, payload = {}) {
    const event = {
      eventId: randomUUID(),
      eventName,
      timestamp: Date.now(),
      ...payload,
    };
    log.debug(`Event published: ${eventName}`, { eventId: event.eventId });
    this.emit(eventName, event);
    return event;
  }

  subscribe(eventName, handler, options = {}) {
    const handlerId = options.handlerId || `${eventName}:${randomUUID().slice(0, 8)}`;

    const wrappedHandler = async (event) => {
      const idempotencyKey = `${handlerId}:${event.eventId}`;
      if (this._processedEvents.has(idempotencyKey)) return;
      this._processedEvents.add(idempotencyKey);
      setTimeout(() => this._processedEvents.delete(idempotencyKey), 60_000);

      try {
        await handler(event);
      } catch (err) {
        log.error(`Event handler failed: ${eventName}`, { error: err, eventId: event.eventId, handlerId });
      }
    };

    this.on(eventName, wrappedHandler);
    this._handlers.set(handlerId, { eventName, handler: wrappedHandler });
    return handlerId;
  }

  unsubscribe(handlerId) {
    const reg = this._handlers.get(handlerId);
    if (reg) {
      this.removeListener(reg.eventName, reg.handler);
      this._handlers.delete(handlerId);
    }
  }
}

export const eventBus = new DomainEventBus();
export default eventBus;
