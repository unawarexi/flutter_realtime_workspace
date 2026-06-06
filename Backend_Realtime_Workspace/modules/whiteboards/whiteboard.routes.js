import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { validate } from "../../middlewares/validate.middleware.js";
import {
  createWhiteboard, listWhiteboards, getWhiteboard,
  updateState, broadcastCursor, addCollaborator, removeCollaborator,
  updateThumbnail, deleteWhiteboard,
} from "./whiteboard.controller.js";
import { createWhiteboardSchema } from "./whiteboard.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

router.post("/", validate(createWhiteboardSchema), createWhiteboard);
router.get("/", listWhiteboards);
router.get("/:id", getWhiteboard);
router.patch("/:id/state", updateState);
router.post("/:id/cursor", broadcastCursor);
router.post("/:id/collaborators/:userId", addCollaborator);
router.delete("/:id/collaborators/:userId", removeCollaborator);
router.patch("/:id/thumbnail", updateThumbnail);
router.delete("/:id", deleteWhiteboard);

export default router;
