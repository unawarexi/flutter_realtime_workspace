import express from 'express';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { tenantMiddleware } from '../../core/auth/tenant.middleware.js';
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { upload, multerErrorHandler } from '../../infrastructure/storage/cloudinary.service.js';

import { documentController } from "./document.controller.js";
import { 
  uploadDocumentSchema, 
  updateDocumentSchema,
  shareDocumentSchema
} from "./document.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Document CRUD
router.post(
  '/', 
  upload.single('file'), 
  multerErrorHandler, 
  validate(uploadDocumentSchema),
  asyncHandler(documentController.uploadDocument)
);

router.get('/', asyncHandler(documentController.getDocuments));
router.get('/:id', asyncHandler(documentController.getDocumentById));

router.put(
  '/:id', 
  validate(updateDocumentSchema),
  asyncHandler(documentController.updateDocument)
);

router.delete('/:id', asyncHandler(documentController.deleteDocument));

// Sharing
router.post(
  '/:id/share', 
  validate(shareDocumentSchema),
  asyncHandler(documentController.shareDocument)
);

export default router;
