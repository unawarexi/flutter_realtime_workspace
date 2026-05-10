import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Whiteboard from "./models/whiteboard.model.js";

class WhiteboardRepository extends BaseRepository {
  constructor() {
    super(Whiteboard, { tenantScoped: true });
  }
}

class WhiteboardService extends BaseService {
  constructor() {
    super(new WhiteboardRepository(), {
      name: "WhiteboardService",
      cachePrefix: "whiteboard",
      cacheTTL: 1800,
    });
  }

  async createWhiteboard(data, tenantId, userId) {
    const newWhiteboard = await this.repository.create({
      ...data,
      tenantId,
      createdBy: userId,
      collaborators: [userId]
    }, { tenantId });

    this.emit("whiteboard.created", { whiteboardId: newWhiteboard._id, tenantId });
    return newWhiteboard;
  }

  async updateState(id, state, tenantId) {
    // Optimistic concurrency can be added here using versioning
    const updated = await this.updateById(id, {
        state,
        $inc: { version: 1 }
    }, { tenantId });
    this.emit("whiteboard.state_updated", { whiteboardId: id, tenantId });
    return updated;
  }
}

export const whiteboardService = new WhiteboardService();
