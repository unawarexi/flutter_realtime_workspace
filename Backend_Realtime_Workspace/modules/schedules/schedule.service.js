// ============================================================================
// TeamSpot — Schedule Service
// Calendar events, recurring schedules, attendee management + notifications
// ============================================================================
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Schedule from "./models/schedule.model.js";
import { notFound, forbidden, conflict } from "../../core/errors/app-error.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser, emitToWorkspace } from "../../infrastructure/websocket/websocket.service.js";
import { KafkaTopics, RabbitQueues, SocketEvents } from "../../config/constants.js";

const SCHEDULE_WS = {
  CREATED: "schedule:created",
  UPDATED: "schedule:updated",
  CANCELLED: "schedule:cancelled",
  RSVP: "schedule:rsvp",
};

class ScheduleRepository extends BaseRepository {
  constructor() {
    super(Schedule, { tenantScoped: true });
  }

  async findInRange(tenantId, userId, startDate, endDate) {
    return this.model.find({
      tenantId,
      deletedAt: null,
      startTime: { $gte: startDate },
      endTime: { $lte: endDate },
      $or: [
        { createdBy: userId },
        { "attendees.userId": userId },
      ],
    }).sort({ startTime: 1 }).lean();
  }

  async checkConflicts(tenantId, userId, startTime, endTime, excludeId = null) {
    const q = {
      tenantId,
      deletedAt: null,
      status: "scheduled",
      $or: [{ createdBy: userId }, { "attendees.userId": userId }],
      $and: [{ startTime: { $lt: endTime } }, { endTime: { $gt: startTime } }],
    };
    if (excludeId) q._id = { $ne: excludeId };
    return this.model.find(q).lean();
  }
}

class ScheduleService extends BaseService {
  constructor() {
    super(new ScheduleRepository(), {
      name: "ScheduleService",
      cachePrefix: "sched",
      cacheTTL: 60,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  async createEvent(data, tenantId, userId) {
    // Conflict check (warn but don't block — let user decide)
    const conflicts = await this.repository.checkConflicts(
      tenantId, userId, new Date(data.startTime), new Date(data.endTime)
    );

    const attendees = (data.attendees || []).map((uid) => ({
      userId: uid,
      status: "pending",
    }));

    // Creator is automatically accepted
    if (!attendees.find((a) => a.userId.toString() === userId)) {
      attendees.unshift({ userId, status: "accepted" });
    }

    const event = await this.repository.create(
      { ...data, tenantId, createdBy: userId, attendees },
      { tenantId }
    );

    // Kafka analytics
    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "schedule.event_created",
      eventId: event._id,
      tenantId,
      createdBy: userId,
      eventType: data.type || "event",
    });

    // WebSocket broadcast to workspace
    emitToWorkspace(tenantId, SCHEDULE_WS.CREATED, {
      eventId: event._id,
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime,
      createdBy: userId,
    });

    // Notify attendees via email + WebSocket
    for (const attendee of attendees.filter((a) => a.userId.toString() !== userId)) {
      emitToUser(attendee.userId.toString(), SCHEDULE_WS.CREATED, {
        eventId: event._id,
        title: event.title,
        startTime: event.startTime,
        invitedBy: userId,
      });

      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email",
        userId: attendee.userId.toString(),
        templateName: "scheduleInvite",
        templateData: {
          eventTitle: event.title,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          description: event.description,
          invitedBy: userId,
        },
      });
    }

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "schedule.event_created",
      resourceType: "schedule",
      resourceId: event._id,
      actor: { id: userId },
      tenantId,
    });

    return { event, conflicts: conflicts.length > 0 ? conflicts : null };
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  async getEventById(id, tenantId) {
    const event = await this.cachedFindById(id, { tenantId });
    if (!event) throw notFound("Schedule event");
    return event;
  }

  async getCalendarView(userId, startDate, endDate, tenantId) {
    return this.repository.findInRange(
      tenantId, userId, new Date(startDate), new Date(endDate)
    );
  }

  async checkAvailability(userId, startTime, endTime, tenantId, excludeId = null) {
    const conflicts = await this.repository.checkConflicts(
      tenantId, userId, new Date(startTime), new Date(endTime), excludeId
    );
    return { available: conflicts.length === 0, conflicts };
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  async updateEvent(id, updates, tenantId, userId) {
    const event = await this.getEventById(id, tenantId);

    if (event.createdBy.toString() !== userId) {
      throw forbidden("Only the event creator can modify it");
    }

    const updated = await this.updateById(id, updates, { tenantId });

    // Notify all attendees of the change
    for (const attendee of event.attendees || []) {
      if (attendee.userId.toString() !== userId) {
        emitToUser(attendee.userId.toString(), SCHEDULE_WS.UPDATED, {
          eventId: id,
          title: event.title,
          changes: Object.keys(updates),
        });
      }
    }

    await publishEvent(KafkaTopics.ANALYTICS_EVENTS, tenantId, {
      type: "schedule.event_updated",
      eventId: id,
      tenantId,
      updatedBy: userId,
    });

    return updated;
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────

  async cancelEvent(id, tenantId, userId, reason = "") {
    const event = await this.getEventById(id, tenantId);

    if (event.createdBy.toString() !== userId) {
      throw forbidden("Only the event creator can cancel it");
    }

    if (event.status === "cancelled") throw conflict("Event already cancelled");

    await this.updateById(
      id,
      { status: "cancelled", cancelledAt: new Date(), cancelledBy: userId },
      { tenantId }
    );

    // Notify all attendees
    for (const attendee of event.attendees || []) {
      emitToUser(attendee.userId.toString(), SCHEDULE_WS.CANCELLED, {
        eventId: id,
        title: event.title,
        reason,
      });

      if (attendee.userId.toString() !== userId) {
        await publishToQueue(RabbitQueues.EMAIL, {
          channel: "email",
          userId: attendee.userId.toString(),
          templateName: "scheduleEventCancelled",
          templateData: {
            eventTitle: event.title,
            startTime: event.startTime,
            reason,
            cancelledBy: userId,
          },
        });
      }
    }

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "schedule.event_cancelled",
      resourceType: "schedule",
      resourceId: id,
      actor: { id: userId },
      tenantId,
      metadata: { reason },
    });
  }

  // ── RSVP ────────────────────────────────────────────────────────────────────

  async rsvp(id, tenantId, userId, status) {
    const validStatuses = ["accepted", "declined", "tentative"];
    if (!validStatuses.includes(status)) throw conflict("Invalid RSVP status");

    const event = await this.getEventById(id, tenantId);

    const isAttendee = (event.attendees || []).some(
      (a) => a.userId.toString() === userId
    );
    if (!isAttendee) throw forbidden("You are not an attendee of this event");

    const updated = await this.updateById(
      id,
      {
        $set: {
          "attendees.$[a].status": status,
          "attendees.$[a].respondedAt": new Date(),
        },
      },
      { tenantId, arrayFilters: [{ "a.userId": userId }] }
    );

    // Notify organiser
    emitToUser(event.createdBy.toString(), SCHEDULE_WS.RSVP, {
      eventId: id,
      respondedBy: userId,
      status,
    });

    return updated;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  async deleteEvent(id, tenantId, userId) {
    const event = await this.getEventById(id, tenantId);
    if (event.createdBy.toString() !== userId) {
      throw forbidden("Only the event creator can delete it");
    }
    await this.updateById(id, { deletedAt: new Date() }, { tenantId });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "schedule.event_deleted",
      resourceType: "schedule",
      resourceId: id,
      actor: { id: userId },
      tenantId,
    });
  }

  // ── Add Attendees ────────────────────────────────────────────────────────────

  async addAttendees(id, userIds, tenantId, actorId) {
    const event = await this.getEventById(id, tenantId);
    if (event.createdBy.toString() !== actorId) {
      throw forbidden("Only the event creator can add attendees");
    }

    const newAttendees = userIds
      .filter((uid) => !(event.attendees || []).some((a) => a.userId.toString() === uid))
      .map((uid) => ({ userId: uid, status: "pending" }));

    if (newAttendees.length === 0) return event;

    const updated = await this.updateById(
      id,
      { $push: { attendees: { $each: newAttendees } } },
      { tenantId }
    );

    // Notify new attendees
    for (const attendee of newAttendees) {
      emitToUser(attendee.userId.toString(), SCHEDULE_WS.CREATED, {
        eventId: id,
        title: event.title,
        startTime: event.startTime,
        invitedBy: actorId,
      });

      await publishToQueue(RabbitQueues.EMAIL, {
        channel: "email",
        userId: attendee.userId.toString(),
        templateName: "scheduleInvite",
        templateData: {
          eventTitle: event.title,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          invitedBy: actorId,
        },
      });
    }

    return updated;
  }
}

export const scheduleService = new ScheduleService();
