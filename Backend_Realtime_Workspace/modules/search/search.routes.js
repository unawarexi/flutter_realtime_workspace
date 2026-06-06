// ============================================================================
// TeamSpot — Search Routes
// ============================================================================

import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import { asyncHandler } from "../../core/base/base.controller.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { searchController } from "./search.controller.js";
import { globalSearchSchema, resourceSearchSchema } from "./search.validation.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

router.get(
  "/", 
  validate(globalSearchSchema),
  asyncHandler(searchController.globalSearch)
);

router.get(
  "/:resource", 
  validate(resourceSearchSchema),
  asyncHandler(searchController.resourceSearch)
);

export default router;
