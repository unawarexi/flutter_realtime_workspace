import express from "express";
import { authenticate } from "../../middlewares/auth.middleware.js";
import { tenantMiddleware } from "../../core/auth/tenant.middleware.js";
import {
  createEvent, listEvents, getEvent, updateEvent, cancelEvent,
  deleteEvent, getCalendarView, checkAvailability, rsvp, addAttendees,
} from "./schedule.controller.js";

const router = express.Router();

router.use(authenticate);
router.use(tenantMiddleware);

// Calendar view (must come before /:id to avoid conflicts)
router.get("/calendar", getCalendarView);
router.get("/availability", checkAvailability);

// CRUD
router.post("/", createEvent);
router.get("/", listEvents);
router.get("/:id", getEvent);
router.put("/:id", updateEvent);
router.patch("/:id/cancel", cancelEvent);
router.delete("/:id", deleteEvent);

// Attendees & RSVP
router.post("/:id/attendees", addAttendees);
router.patch("/:id/rsvp", rsvp);

export default router;
