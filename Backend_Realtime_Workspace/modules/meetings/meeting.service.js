import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Meeting from "./models/meeting.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { VideoService } from "../communication/video.service.js";

class MeetingRepository extends BaseRepository {
  constructor() {
    super(Meeting, { tenantScoped: true });
  }
}

class MeetingService extends BaseService {
  constructor() {
    super(new MeetingRepository(), {
      name: "MeetingService",
      cachePrefix: "meeting",
      cacheTTL: 1800,
    });
    this.videoService = new VideoService();
  }

  async createMeeting(data, tenantId, userContext) {
    const newMeeting = await this.repository.create({
      ...data,
      tenantId,
      organizer: {
        userId: userContext._id,
        name: userContext.fullName || userContext.email,
        email: userContext.email
      },
      status: "scheduled"
    }, { tenantId });

    if (newMeeting.meetingType === "Virtual") {
        // Prepare room name
        const roomName = `meeting_${newMeeting._id}`;
        await this.updateById(newMeeting._id, {
            "location.meetingLink": roomName,
            "location.platform": "LiveKit"
        }, { tenantId });
    }

    this.emit("meeting.created", { meetingId: newMeeting._id, tenantId, organizer: userContext._id });
    return newMeeting;
  }

  async getMeetingById(id, tenantId) {
    const meeting = await this.cachedFindById(id, { tenantId });
    if (!meeting) throw new AppError(HttpStatus.NOT_FOUND, "Meeting not found", "E3013");
    return meeting;
  }

  async updateMeeting(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("meeting.updated", { meetingId: id, tenantId });
    return updated;
  }

  async rsvp(id, userId, status, tenantId) {
    const meeting = await this.getMeetingById(id, tenantId);
    const participantIndex = meeting.participants.findIndex(p => p.userId.toString() === userId.toString());
    
    if (participantIndex === -1) {
        throw new AppError(HttpStatus.FORBIDDEN, "User is not a participant in this meeting", "E4005");
    }

    // Direct mongoose update syntax for array element
    const updated = await this.repository.model.findOneAndUpdate(
        { _id: id, tenantId, "participants.userId": userId },
        { 
            $set: { 
                "participants.$.status": status,
                "participants.$.responseDate": new Date()
            }
        },
        { new: true }
    );
    
    // We invalidate cache manually since we used custom query
    await this.invalidateCache(id);

    this.emit("meeting.rsvp", { meetingId: id, tenantId, userId, status });
    return updated;
  }

  async joinMeeting(id, userContext, tenantId) {
    const meeting = await this.getMeetingById(id, tenantId);

    if (meeting.meetingType !== "Virtual") {
        throw new AppError(HttpStatus.BAD_REQUEST, "This is not a virtual meeting", "E4006");
    }

    const roomName = meeting.location.meetingLink || `meeting_${meeting._id}`;
    
    // Auto-create livekit room if it doesn't exist (handled by video.service natively or we explicitly create it)
    if (meeting.status === "scheduled") {
        await this.updateById(id, { status: "ongoing", actualStartTime: new Date() }, { tenantId });
        await this.videoService.createManagedRoom({ roomName, tenantId });
    }

    // Generate token
    const tokenPayload = await this.videoService.generateRoomToken({
        roomName,
        identity: userContext._id.toString(),
        displayName: userContext.fullName || userContext.email,
        tenantId,
        permissions: {
            canAdminRoom: meeting.organizer.userId.toString() === userContext._id.toString()
        }
    });

    return { meeting, token: tokenPayload.token, roomName };
  }
}

export const meetingService = new MeetingService();
