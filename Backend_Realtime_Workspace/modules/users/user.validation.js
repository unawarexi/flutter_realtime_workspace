import { body, param } from "express-validator";

export const updateUserSchema = [
  body("fullName").optional().trim().isLength({ max: 100 }),
  body("displayName").optional().trim().isLength({ max: 50 }),
  body("phoneNumber").optional().isString(),
  body("timezone").optional().isString(),
  body("bio").optional().isString().isLength({ max: 500 }),
  body("department").optional().isString(),
  body("workType").optional().isIn(["Full-time", "Part-time", "Freelancer", "Intern", "Contractor"]),
];

export const updatePreferencesSchema = [
  body("theme").optional().isIn(["light", "dark", "system"]),
  body("language").optional().isString(),
  body("notifications").optional().isObject(),
];
