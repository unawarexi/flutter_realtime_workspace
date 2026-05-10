import express from 'express';
import { firebaseAuthMiddleware } from '../../core/auth/firebase-auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { whiteboardController } from "./whiteboard.controller.js";
import { createWhiteboardSchema, updateWhiteboardSchema } from "./whiteboard.validation.js";

const router = express.Router();

router.use(firebaseAuthMiddleware);
router.use(tenantMiddleware);

router.post('/', validate(createWhiteboardSchema), asyncHandler(whiteboardController.createWhiteboard));
router.get('/', asyncHandler(whiteboardController.getWhiteboards));
router.get('/:id', asyncHandler(whiteboardController.getWhiteboardById));
router.put('/:id', validate(updateWhiteboardSchema), asyncHandler(whiteboardController.updateWhiteboard));
router.delete('/:id', asyncHandler(whiteboardController.deleteWhiteboard));
router.post('/:id/state', asyncHandler(whiteboardController.updateState));

export default router;
