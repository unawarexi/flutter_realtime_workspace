// ============================================================================
// TeamSpot — Template Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";
import {
  validateCreateTemplate,
  validateUpdateTemplate,
  validateListTemplates,
} from "./template.validation.js";
import {
  createTemplate,
  listTemplates,
  getTemplate,
  updateTemplate,
  deleteTemplate,
  previewTemplate,
} from "./template.controller.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

router.post("/",            validate(validateCreateTemplate), createTemplate);
router.get("/",             validate(validateListTemplates),  listTemplates);
router.get("/:id",          getTemplate);
router.put("/:id",          validate(validateUpdateTemplate), updateTemplate);
router.delete("/:id",       deleteTemplate);
router.post("/:id/preview", previewTemplate);

export default router;
