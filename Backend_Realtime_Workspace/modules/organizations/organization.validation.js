import { body, param } from "express-validator";

export const createOrganizationSchema = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Organization name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("Organization name must be between 2 and 100 characters"),
  body("slug")
    .trim()
    .notEmpty()
    .withMessage("Slug is required")
    .matches(/^[a-z0-9-]+$/)
    .withMessage("Slug can only contain lowercase letters, numbers, and hyphens"),
  body("industry").optional().isString(),
  body("size").optional().isIn(["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"]),
  body("domain").optional().isURL().withMessage("Domain must be a valid URL"),
];

export const updateOrganizationSchema = [
  param("id").isMongoId().withMessage("Invalid organization ID"),
  body("name").optional().trim().isLength({ min: 2, max: 100 }),
  body("industry").optional().isString(),
  body("size").optional().isIn(["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"]),
  body("website").optional().isURL(),
  body("primaryColor").optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage("Invalid color hex"),
  body("timezone").optional().isString(),
];

export const updateSettingsSchema = [
  param("id").isMongoId().withMessage("Invalid organization ID"),
  body("enforced2FA").optional().isBoolean(),
  body("allowedAuthProviders").optional().isArray(),
  body("sessionTimeoutMinutes").optional().isInt({ min: 15 }),
];

export const inviteMemberSchema = [
  param("id").isMongoId().withMessage("Invalid organization ID"),
  body("email").isEmail().withMessage("Valid email is required"),
  body("role").optional().isString(),
];
