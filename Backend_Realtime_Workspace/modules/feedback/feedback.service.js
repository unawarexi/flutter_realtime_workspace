import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Feedback from "./models/feedback.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";

class FeedbackRepository extends BaseRepository {
  constructor() {
    super(Feedback, { tenantScoped: true });
  }
}

class FeedbackService extends BaseService {
  constructor() {
    super(new FeedbackRepository(), {
      name: "FeedbackService",
      cachePrefix: "feedback",
      cacheTTL: 1800,
    });
  }

  async createFeedback(data, tenantId, userId, files = []) {
    const feedbackData = {
      ...data,
      tenantId,
      userId,
      attachments: []
    };

    if (files && files.length > 0) {
      for (const file of files) {
        const uploadResult = await uploadBuffer(file.buffer, {
          folder: `teamspot/feedback/${tenantId}`,
          resourceType: "auto"
        });
        feedbackData.attachments.push({
          url: uploadResult.url,
          filename: file.originalname
        });
      }
    }

    const newFeedback = await this.repository.create(feedbackData, { tenantId });
    this.emit("feedback.created", { feedbackId: newFeedback._id, tenantId });
    return newFeedback;
  }

  async getFeedbackById(id, tenantId) {
    const feedback = await this.cachedFindById(id, { tenantId });
    if (!feedback) throw new AppError(HttpStatus.NOT_FOUND, "Feedback not found", "E3015");
    return feedback;
  }

  async updateFeedback(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("feedback.updated", { feedbackId: id, tenantId });
    return updated;
  }

  async respondToFeedback(id, content, tenantId, responderId) {
    const feedback = await this.getFeedbackById(id, tenantId);
    
    const updated = await this.updateById(id, {
      response: {
        content,
        respondedBy: responderId,
        respondedAt: new Date()
      },
      status: "acknowledged" // auto-update status when responded
    }, { tenantId });

    this.emit("feedback.responded", { feedbackId: id, tenantId, responderId });
    return updated;
  }
}

export const feedbackService = new FeedbackService();
