import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Ticket from "./models/ticket.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";

class TicketRepository extends BaseRepository {
  constructor() {
    super(Ticket, { tenantScoped: true });
  }
}

class TicketService extends BaseService {
  constructor() {
    super(new TicketRepository(), {
      name: "TicketService",
      cachePrefix: "ticket",
      cacheTTL: 1800,
    });
  }

  async createTicket(data, tenantId, orgId, userId, files = []) {
    const count = await this.repository.count({ orgId }, { tenantId });
    const ticketNumber = `TKT-${String(count + 1).padStart(5, '0')}`;

    const newTicket = await this.repository.create({
      ...data,
      ticketNumber,
      tenantId,
      orgId,
      reporter: userId,
      // SLA logic simplified
      sla: {
        responseDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
        resolutionDeadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      }
    }, { tenantId });

    if (files.length > 0) {
      for (const file of files) {
        await this.addAttachment(newTicket._id, file, tenantId);
      }
    }

    this.emit("ticket.created", { ticketId: newTicket._id, tenantId, orgId, reporter: userId });
    return newTicket;
  }

  async getTicketById(id, tenantId) {
    const ticket = await this.cachedFindById(id, { tenantId });
    if (!ticket) throw new AppError(HttpStatus.NOT_FOUND, "Ticket not found", "E3010");
    return ticket;
  }

  async updateTicket(id, updates, tenantId, userId) {
    const ticket = await this.getTicketById(id, tenantId);
    
    if (updates.status && updates.status !== ticket.status) {
      if (updates.status === 'resolved') updates.resolvedAt = new Date();
      if (updates.status === 'closed') updates.closedAt = new Date();
      this.emit("ticket.status_changed", { ticketId: id, tenantId, oldStatus: ticket.status, newStatus: updates.status, userId });
    }

    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("ticket.updated", { ticketId: id, tenantId, updates, userId });
    return updated;
  }

  async addComment(id, content, internal, tenantId, userId) {
    const ticket = await this.getTicketById(id, tenantId);
    const isFirstResponse = !ticket.firstResponseAt && userId.toString() !== ticket.reporter.toString();

    const updates = {
      $push: { comments: { userId, content, internal, createdAt: new Date() } }
    };
    if (isFirstResponse) updates.firstResponseAt = new Date();

    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("ticket.comment_added", { ticketId: id, tenantId, userId, internal });
    return updated;
  }

  async addAttachment(id, file, tenantId) {
    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/tickets/${id}`,
      resourceType: "auto"
    });

    const attachment = {
      url: uploadResult.url,
      publicId: uploadResult.publicId,
      filename: file.originalname,
      mimeType: file.mimetype,
      bytes: uploadResult.bytes
    };

    const updated = await this.updateById(id, {
      $push: { attachments: attachment }
    }, { tenantId });

    return attachment;
  }
}

export const ticketService = new TicketService();
