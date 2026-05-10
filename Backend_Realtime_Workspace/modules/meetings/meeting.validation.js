import { body, param } from "express-validator";

export const createMeetingSchema = [
  body("meetingTitle").trim().notEmpty().withMessage("Meeting title is required").isLength({ max: 200 }),
  body("description").optional().isString().isLength({ max: 2000 }),
  body("agenda").optional().isString().isLength({ max: 5000 }),
  body("meetingDate").isISO8601().toDate().withMessage("Valid meeting date is required"),
  body("meetingTime").isObject(),
  body("meetingTime.start").isString().notEmpty(),
  body("meetingTime.end").isString().notEmpty(),
  body("duration").isInt({ min: 5, max: 480 }),
  body("meetingType").isIn(["Virtual", "Physical"]),
  body("participants").optional().isArray(),
];

export const updateMeetingSchema = [
  param("id").isMongoId().withMessage("Invalid meeting ID"),
  body("meetingTitle").optional().trim().notEmpty().isLength({ max: 200 }),
  body("meetingDate").optional().isISO8601().toDate(),
  body("status").optional().isIn(["scheduled", "ongoing", "ended", "cancelled", "postponed"]),
];

export const rsvpMeetingSchema = [
  param("id").isMongoId().withMessage("Invalid meeting ID"),
  body("status").isIn(["accepted", "declined", "tentative"]),
];
