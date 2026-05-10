import { asyncHandler } from "../../core/base/base.controller.js";
import { ticketService } from "./ticket.service.js";
import { created, success, paginated, noContent } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
  orgId:    req.user?.orgId || null,
});

export const createTicket = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const ticket = await ticketService.createTicket({ ...req.body, tenantId, orgId, userId, files: req.files || [] });
  return created(res, ticket, "Ticket created");
});

export const listTickets = asyncHandler(async (req, res) => {
  const { tenantId, userId, orgId } = ctx(req);
  const result = await ticketService.listTickets({ ...req.query, tenantId, orgId, userId });
  return paginated(res, result, "Tickets retrieved");
});

export const getTicket = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const ticket = await ticketService.getTicketById(req.params.id, tenantId);
  return success(res, ticket, "Ticket retrieved");
});

export const updateTicket = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const ticket = await ticketService.updateTicket({ id: req.params.id, updates: req.body, tenantId, userId });
  return success(res, ticket, "Ticket updated");
});

export const assignTicket = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const ticket = await ticketService.assignTicket({ id: req.params.id, assignedTo: req.body.assignedTo, tenantId, assignedBy: userId });
  return success(res, ticket, "Ticket assigned");
});

export const addComment = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const ticket = await ticketService.addComment({ id: req.params.id, content: req.body.content, internal: req.body.internal, tenantId, userId });
  return success(res, ticket, "Comment added");
});

export const uploadAttachment = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  if (!req.file) return success(res, null, "No file");
  const att = await ticketService.addAttachment({ id: req.params.id, file: req.file, tenantId });
  return created(res, att, "Attachment uploaded");
});

export const ticketController = { createTicket, listTickets, getTicket, updateTicket, assignTicket, addComment, uploadAttachment };
