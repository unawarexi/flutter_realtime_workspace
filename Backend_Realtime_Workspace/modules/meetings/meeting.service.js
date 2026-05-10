// ============================================================================
// TeamSpot — Meeting Service (full infrastructure integration)
// LiveKit for virtual rooms, Kafka for analytics, RabbitMQ for reminders/email
// ============================================================================

import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Meeting from "./models/meeting.model.js";
import { VideoService } from "../communication/video.service.js";
import { notFound, forbidden, badRequest, conflict } from "../../core/errors/app-error.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToWorkspace, emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { eventBus } from "../../core/events/event-bus.js";
import { DomainEvents } from "../../core/events/event-contracts.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("MeetingService");

class MeetingRepository extends BaseRepository {
  constructor() { super(Meeting, { tenantScoped: true }); }
}

class MeetingService extends BaseService {
  constructor() {
    super(new MeetingRepository(), {
      name: "MeetingService",
      cachePrefix: "meeting",
      cacheTTL: CacheTTL.PROJECT || 60,
    });
    this.videoService = new VideoService();
  }

  // ── Create Meeting ───────────────────────────────────────────────────────────
  async createMeeting({ tenantId, workspaceId, userContext, meetingTitle, description, agenda,
    meetingDate, meetingTime, duration, timezone = "UTC", meetingType = "Virtual",
    participants = [], repeatOption = "None", recurrenceEndDate, reminderSettings, location,
  }) {
    const meeting = await this.repository.create({
      tenantId, workspaceId,
      meetingTitle, description, agenda,
      meetingDate: new Date(meetingDate), meetingTime, duration, timezone,
      meetingType, repeatOption, recurrenceEndDate, reminderSettings, location,
      organizer: {
        userId: userContext._id || userContext.id,
        name: userContext.fullName || userContext.email,
        email: userContext.email,
      },
      participants: participants.map(p => ({ ...p, status: "invited" })),
      status: "scheduled",
    });

    // LiveKit room for virtual meetings
    if (meetingType === "Virtual") {
      const roomName = `meeting_${meeting._id}`;
      try {
        await this.videoService.createManagedRoom({ roomName, tenantId });
      } catch (err) {
        log.warn({ err: err.message }, "LiveKit room pre-creation failed; will create on join");
      }
      await this.repository.updateById(meeting._id, {
        "location.meetingLink": roomName,
        "location.platform": "LiveKit",
      }, { tenantId });
    }

    // Notify workspace
    if (workspaceId) {
      emitToWorkspace(workspaceId, SocketEvents.MEETING_STARTED, { action: "scheduled", meetingId: meeting._id, meetingTitle });
    }

    // Notify each participant
    for (const p of participants) {
      if (p.userId) emitToUser(String(p.userId), SocketEvents.NOTIFICATION, { type: "meeting.invited", meetingId: meeting._id, meetingTitle });
    }

    // Queue invitation emails
    for (const p of participants) {
      if (p.email) {
        await publishToQueue(RabbitQueues.EMAIL, {
          channel: "email",
          to: p.email,
          templateName: "meetingInvite",
          templateData: {
            recipientName: p.name || p.email,
            meetingTitle,
            meetingDate: meeting.meetingDate,
            meetingTime: meetingTime?.start,
            duration,
            timezone,
            organizerName: userContext.fullName || userContext.email,
            meetingLink: meetingType === "Virtual" ? `${process.env.FRONTEND_URL}/meetings/${meeting._id}` : null,
            location: meetingType === "Physical" ? location?.address : null,
          },
        });
      }
    }

    // Queue reminder (simplified — in production, use a scheduler like Agenda/BullMQ)
    await publishToQueue(RabbitQueues.NOTIFICATION, {
      channel: "schedule_reminder",
      meetingId: meeting._id.toString(),
      scheduledAt: new Date(new Date(meetingDate).getTime() - 15 * 60_000).toISOString(), // 15 min before
      tenantId,
    });

    await publishEvent(KafkaTopics.MEETING_EVENTS, tenantId, {
      type: "meeting.scheduled",
      meetingId: meeting._id,
      tenantId, workspaceId,
      organizer: userContext._id,
      participantCount: participants.length,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "meeting.created", resourceType: "meeting",
      resourceId: meeting._id, actor: { id: userContext._id }, tenantId,
    });

    eventBus.publish(DomainEvents.MEETING_CREATED, { meetingId: meeting._id, tenantId });
    return meeting;
  }

  // ── List Meetings ────────────────────────────────────────────────────────────
  async listMeetings({ tenantId, workspaceId, userId, status, from, to, page = 1, limit = 20 }) {
    const filter = {
      tenantId,
      $or: [
        { "organizer.userId": userId },
        { "participants.userId": userId },
      ],
    };
    if (workspaceId) filter.workspaceId = workspaceId;
    if (status)      filter.status = status;
    if (from || to) {
      filter.meetingDate = {};
      if (from) filter.meetingDate.$gte = new Date(from);
      if (to)   filter.meetingDate.$lte = new Date(to);
    }
    return this.repository.paginate({ filter, page, limit, sort: { meetingDate: 1 } }, { tenantId });
  }

  // ── Get by ID ────────────────────────────────────────────────────────────────
  async getMeetingById(id, tenantId) {
    const meeting = await this.cachedFindById(id, { tenantId });
    if (!meeting) throw notFound("Meeting");
    return meeting;
  }

  // ── Update ───────────────────────────────────────────────────────────────────
  async updateMeeting({ id, updates, tenantId, userId }) {
    const meeting = await this.getMeetingById(id, tenantId);
    if (String(meeting.organizer.userId) !== String(userId)) throw forbidden("Only the organizer can update this meeting");
    if (meeting.status === "ended" || meeting.status === "cancelled") throw badRequest("Cannot update a completed or cancelled meeting");

    const updated = await this.updateById(id, updates, { tenantId });
    emitToWorkspace(String(meeting.workspaceId), SocketEvents.MEETING_STARTED, { action: "updated", meetingId: id });
    return updated;
  }

  // ── Cancel ───────────────────────────────────────────────────────────────────
  async cancelMeeting({ id, tenantId, userId, reason }) {
    const meeting = await this.getMeetingById(id, tenantId);
    if (String(meeting.organizer.userId) !== String(userId)) throw forbidden("Only the organizer can cancel this meeting");

    const updated = await this.updateById(id, { status: "cancelled", cancellationReason: reason }, { tenantId });

    // Notify participants
    for (const p of meeting.participants) {
      if (p.userId) emitToUser(String(p.userId), SocketEvents.MEETING_ENDED, { meetingId: id, status: "cancelled" });
      if (p.email) {
        await publishToQueue(RabbitQueues.EMAIL, {
          channel: "email",
          to: p.email,
          templateName: "meetingCancelled",
          templateData: { recipientName: p.name || p.email, meetingTitle: meeting.meetingTitle, reason },
        });
      }
    }

    await publishEvent(KafkaTopics.MEETING_EVENTS, tenantId, { type: "meeting.cancelled", meetingId: id, tenantId, userId });
    return updated;
  }

  // ── RSVP ─────────────────────────────────────────────────────────────────────
  async rsvp({ id, userId, status, tenantId }) {
    const meeting = await this.getMeetingById(id, tenantId);
    const pIdx = meeting.participants.findIndex(p => String(p.userId) === String(userId));
    if (pIdx === -1) throw forbidden("You are not a participant in this meeting");

    const updated = await this.repository.model.findOneAndUpdate(
      { _id: id, tenantId, "participants.userId": userId },
      { $set: { "participants.$.status": status, "participants.$.responseDate": new Date() } },
      { new: true }
    );

    emitToUser(String(meeting.organizer.userId), SocketEvents.NOTIFICATION, {
      type: "meeting.rsvp",
      meetingId: id,
      userId, status,
      participantName: meeting.participants[pIdx]?.name,
    });

    await publishEvent(KafkaTopics.MEETING_EVENTS, tenantId, { type: "meeting.rsvp", meetingId: id, userId, status, tenantId });
    return updated;
  }

  // ── Join (get LiveKit token) ──────────────────────────────────────────────────
  async joinMeeting({ id, tenantId, userContext }) {
    const meeting = await this.getMeetingById(id, tenantId);
    if (meeting.meetingType !== "Virtual") throw badRequest("This is not a virtual meeting");
    if (meeting.status === "cancelled") throw badRequest("This meeting was cancelled");

    const roomName = meeting.location?.meetingLink || `meeting_${meeting._id}`;
    const isOrganizer = String(meeting.organizer.userId) === String(userContext._id || userContext.id);

    if (meeting.status === "scheduled") {
      await this.updateById(id, { status: "ongoing", actualStartTime: new Date() }, { tenantId });
      emitToWorkspace(String(meeting.workspaceId), SocketEvents.MEETING_STARTED, { meetingId: id, meetingTitle: meeting.meetingTitle });

      // Notify participants meeting started
      for (const p of meeting.participants) {
        if (p.userId && String(p.userId) !== String(userContext._id)) {
          emitToUser(String(p.userId), SocketEvents.MEETING_STARTED, { meetingId: id, meetingTitle: meeting.meetingTitle });
        }
      }
    }

    const tokenPayload = await this.videoService.generateRoomToken({
      roomName, tenantId,
      identity: String(userContext._id || userContext.id),
      displayName: userContext.fullName || userContext.email,
      permissions: { canAdminRoom: isOrganizer },
    });

    await this.repository.model.findOneAndUpdate(
      { _id: id, "participants.userId": userContext._id },
      { $set: { "participants.$.joinedAt": new Date() } }
    );

    await publishEvent(KafkaTopics.MEETING_EVENTS, tenantId, {
      type: "meeting.participant_joined",
      meetingId: id, userId: userContext._id, tenantId,
    });

    return { meeting, token: tokenPayload.token, roomName };
  }

  // ── End Meeting ──────────────────────────────────────────────────────────────
  async endMeeting({ id, tenantId, userId }) {
    const meeting = await this.getMeetingById(id, tenantId);
    if (String(meeting.organizer.userId) !== String(userId)) throw forbidden("Only the organizer can end the meeting");

    const updated = await this.updateById(id, {
      status: "ended",
      actualEndTime: new Date(),
    }, { tenantId });

    emitToWorkspace(String(meeting.workspaceId), SocketEvents.MEETING_ENDED, { meetingId: id });

    await publishEvent(KafkaTopics.MEETING_EVENTS, tenantId, { type: "meeting.ended", meetingId: id, tenantId, userId });
    return updated;
  }
}

export const meetingService = new MeetingService();
