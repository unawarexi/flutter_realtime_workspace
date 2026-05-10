import BaseController from "../../core/base/base.controller.js";
import { ticketService } from "./ticket.service.js";

class TicketController extends BaseController {
  
  createTicket = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const ticket = await ticketService.createTicket(req.body, tenantId, orgId, userId, files);
    return BaseController.sendCreated(res, ticket, "Ticket created successfully");
  };

  getTickets = async (req, res) => {
    const { tenantId, orgId } = BaseController.getContext(req);
    const { status, priority, type, assignee, reporter } = req.query;
    
    const filter = { orgId };
    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (type) filter.type = type;
    if (assignee) filter.assignee = assignee;
    if (reporter) filter.reporter = reporter;
    
    const pagination = BaseController.getPagination(req);
    const result = await ticketService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Tickets retrieved");
  };

  getTicketById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const ticket = await ticketService.getTicketById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, ticket, "Ticket retrieved");
  };

  updateTicket = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const ticket = await ticketService.updateTicket(req.params.id, req.body, tenantId, userId);
    return BaseController.sendSuccess(res, ticket, "Ticket updated");
  };

  deleteTicket = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await ticketService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Ticket deleted");
  };

  addComment = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const { content, internal } = req.body;
    const ticket = await ticketService.addComment(req.params.id, content, internal || false, tenantId, userId);
    return BaseController.sendSuccess(res, ticket, "Comment added");
  };

  uploadAttachment = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    if (!req.file) return BaseController.sendSuccess(res, null, "No file provided");
    const attachment = await ticketService.addAttachment(req.params.id, req.file, tenantId);
    return BaseController.sendCreated(res, attachment, "Attachment uploaded");
  };
}

export const ticketController = new TicketController();
