// ============================================================================
// TeamSpot — Ticket Routes
// ============================================================================

import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { ticketController } from "./ticket.controller.js";
import { 
  createTicketSchema, 
  updateTicketSchema
} from "./ticket.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Ticket CRUD
router.post(
  '/', 
  upload.array('attachments', 5), 
  multerErrorHandler, 
  validate(createTicketSchema),
  asyncHandler(ticketController.createTicket)
);

router.get('/', asyncHandler(ticketController.getTickets));
router.get('/:id', asyncHandler(ticketController.getTicketById));

router.put(
  '/:id', 
  validate(updateTicketSchema),
  asyncHandler(ticketController.updateTicket)
);

router.delete('/:id', asyncHandler(ticketController.deleteTicket));

// Features
router.post(
  '/:id/comments', 
  asyncHandler(ticketController.addComment)
);

// Attachments
router.post(
  '/:id/attachments', 
  upload.single('attachment'), 
  multerErrorHandler, 
  asyncHandler(ticketController.uploadAttachment)
);

export default router;
