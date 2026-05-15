import { body, param } from "express-validator";

export const createTeamSchema = [
  body("name").trim().notEmpty().withMessage("Team name is required").isLength({ max: 100 }),
  body("description").optional().isString().isLength({ max: 500 }),
  body("industry").optional().isString(),
  body("size").optional().isIn(["1-10", "11-50", "51-100", "101-500", "500+"]),
  body("type").optional().isIn(["company", "agency", "startup", "non-profit", "educational", "personal"]),
  body("workspaceId").optional().isMongoId().withMessage("Invalid workspace ID"),
];

export const updateTeamSchema = [
  param("id").isMongoId().withMessage("Invalid team ID"),
  body("name").optional().trim().isLength({ max: 100 }),
  body("description").optional().isString().isLength({ max: 500 }),
  body("industry").optional().isString(),
  body("size").optional().isIn(["1-10", "11-50", "51-100", "101-500", "500+"]),
  body("type").optional().isIn(["company", "agency", "startup", "non-profit", "educational", "personal"]),
];

export const inviteTeamMemberSchema = [
  param("id").isMongoId().withMessage("Invalid team ID"),
  body("email").isEmail().withMessage("Valid email is required"),
  body("role").optional().isIn(["admin", "manager", "member", "viewer", "guest"]),
  body("message").optional().isString().isLength({ max: 500 }),
];

// Aliases for legacy team.routes.js imports
export const validateTeamInput      = createTeamSchema;
export const validateInviteInput    = inviteTeamMemberSchema;
export const validateMemberRoleUpdate = [
  param("id").isMongoId().withMessage("Invalid team ID"),
  body("role").isIn(["admin", "manager", "member", "viewer", "guest"]).withMessage("Invalid role"),
];
