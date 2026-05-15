import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import mongoose from "mongoose";
import { createLogger } from "../../observability/logger.js";
import { generateCSV, generateXLSX } from "./report-gen-analytics.controller.js";
import {
  generateAnalyticsReport,
  generateProjectReport,
  generateTeamReport,
  generateTicketReport,
  generateAuditReport,
  generateWorkspaceSummary,
} from "../../infrastructure/pdf/pdf-renderer.js";

const log = createLogger("AnalyticsService");

// ─── Column definitions per entity type ───────────────────────────────────────
const REPORT_CONFIGS = {
  tasks: {
    title: "Tasks Report",
    columns: [
      { header: "Key", key: "key" },
      { header: "Title", key: "title" },
      { header: "Status", key: "status" },
      { header: "Priority", key: "priority" },
      { header: "Assignee", key: "assignedTo" },
      { header: "Due Date", key: "dueDate" },
      { header: "Logged Hours", key: "loggedHours" },
    ],
    fetch: (q) => mongoose.model("Task").find(q).lean(),
    transform: (row) => ({
      ...row,
      assignedTo: row.assignedTo?.toString() || "Unassigned",
      dueDate: row.dueDate ? new Date(row.dueDate).toLocaleDateString("en-GB") : "—",
    }),
  },
  projects: {
    title: "Projects Report",
    columns: [
      { header: "Name", key: "name" },
      { header: "Template", key: "template" },
      { header: "Status", key: "status" },
      { header: "Priority", key: "priority" },
      { header: "Created", key: "createdAt" },
    ],
    fetch: (q) => mongoose.model("Project").find(q).lean(),
    transform: (row) => ({
      ...row,
      createdAt: row.createdAt ? new Date(row.createdAt).toLocaleDateString("en-GB") : "—",
    }),
  },
  tickets: {
    title: "Tickets Report",
    columns: [
      { header: "Ticket #", key: "ticketNumber" },
      { header: "Title", key: "title" },
      { header: "Type", key: "type" },
      { header: "Priority", key: "priority" },
      { header: "Status", key: "status" },
      { header: "Created", key: "createdAt" },
    ],
    fetch: (q) => mongoose.model("Ticket").find(q).lean(),
    transform: (row) => ({
      ...row,
      createdAt: row.createdAt ? new Date(row.createdAt).toLocaleDateString("en-GB") : "—",
    }),
  },
  issues: {
    title: "Issues Report",
    columns: [
      { header: "Key", key: "key" },
      { header: "Title", key: "title" },
      { header: "Type", key: "type" },
      { header: "Severity", key: "severity" },
      { header: "Status", key: "status" },
      { header: "Priority", key: "priority" },
      { header: "Created", key: "createdAt" },
    ],
    fetch: (q) => mongoose.model("Issue").find(q).lean(),
    transform: (row) => ({
      ...row,
      createdAt: row.createdAt ? new Date(row.createdAt).toLocaleDateString("en-GB") : "—",
    }),
  },
  meetings: {
    title: "Meetings Report",
    columns: [
      { header: "Title", key: "meetingTitle" },
      { header: "Date", key: "meetingDate" },
      { header: "Duration (min)", key: "duration" },
      { header: "Organiser", key: "organizer" },
      { header: "Status", key: "status" },
    ],
    fetch: (q) => mongoose.model("Meeting").find(q).lean(),
    transform: (row) => ({
      ...row,
      meetingDate: row.meetingDate ? new Date(row.meetingDate).toLocaleDateString("en-GB") : "—",
      organizer: row.organizer?.name || "—",
    }),
  },
  users: {
    title: "Members Report",
    columns: [
      { header: "Full Name", key: "fullName" },
      { header: "Email", key: "email" },
      { header: "Department", key: "department" },
      { header: "Work Type", key: "workType" },
      { header: "Joined", key: "createdAt" },
    ],
    fetch: (q) => mongoose.model("User").find(q).select("-firebaseUid -__v").lean(),
    transform: (row) => ({
      ...row,
      createdAt: row.createdAt ? new Date(row.createdAt).toLocaleDateString("en-GB") : "—",
    }),
  },
  channels: {
    title: "Channels Report",
    columns: [
      { header: "Name", key: "name" },
      { header: "Type", key: "type" },
      { header: "Members", key: "memberCount" },
      { header: "Messages", key: "messageCount" },
      { header: "Status", key: "status" },
      { header: "Created", key: "createdAt" },
    ],
    fetch: (q) => mongoose.model("Channel").find(q).lean(),
    transform: (row) => ({
      ...row,
      memberCount: row.members?.length ?? 0,
      createdAt: row.createdAt ? new Date(row.createdAt).toLocaleDateString("en-GB") : "—",
    }),
  },
};

class AnalyticsService {
  constructor() {
    this.name = "AnalyticsService";
  }

  async getDashboardStats(tenantId, options = {}) {
    const { startDate, endDate } = options;
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);

    const query = { tenantId };
    if (Object.keys(dateFilter).length > 0) {
      query.createdAt = dateFilter;
    }

    try {
      const [projectsCount, tasksCount, usersCount, meetingsCount, ticketsCount, issuesCount] = await Promise.all([
        mongoose.model("Project").countDocuments(query),
        mongoose.model("Task").countDocuments(query),
        mongoose.model("User").countDocuments({ tenantId }),
        mongoose.model("Meeting").countDocuments(query),
        mongoose.model("Ticket").countDocuments({ tenantId }).catch(() => 0),
        mongoose.model("Issue").countDocuments(query).catch(() => 0),
      ]);

      return {
        projects: projectsCount,
        tasks: tasksCount,
        users: usersCount,
        meetings: meetingsCount,
        tickets: ticketsCount,
        issues: issuesCount,
      };
    } catch (error) {
      log.error("Failed to aggregate dashboard stats", { error, tenantId });
      throw new AppError(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to aggregate statistics", "E5000");
    }
  }

  /**
   * Generate a report for a given entity type and output format.
   * @param {'tasks'|'projects'|'tickets'|'issues'|'meetings'|'users'|'channels'} type
   * @param {'csv'|'xlsx'|'pdf'} format
   * @param {string} tenantId
   * @param {{ startDate?, endDate?, workspaceId? }} options
   */
  async generateReport(type, format, tenantId, options = {}) {
    const config = REPORT_CONFIGS[type];
    if (!config) {
      throw new AppError(HttpStatus.BAD_REQUEST, `Unsupported report type: ${type}. Supported: ${Object.keys(REPORT_CONFIGS).join(", ")}`, "E4009");
    }
    if (!["csv", "xlsx", "pdf"].includes(format)) {
      throw new AppError(HttpStatus.BAD_REQUEST, "Unsupported format. Use csv, xlsx, or pdf.", "E4010");
    }

    const query = { tenantId };
    if (options.startDate || options.endDate) {
      query.createdAt = {};
      if (options.startDate) query.createdAt.$gte = new Date(options.startDate);
      if (options.endDate) query.createdAt.$lte = new Date(options.endDate);
    }
    if (options.workspaceId) query.workspaceId = options.workspaceId;

    log.info("Generating report", { type, format, tenantId });

    const raw = await config.fetch(query);
    const data = raw.map(config.transform);

    if (format === "csv") return generateCSV(data, config.columns);
    if (format === "xlsx") return generateXLSX(data, config.columns);

    // PDF — use specialised generator when available
    const metrics = await this.getDashboardStats(tenantId, options).catch(() => ({}));
    return generateAnalyticsReport({
      title: config.title,
      subtitle: `Tenant: ${tenantId} · Generated ${new Date().toLocaleDateString("en-GB")}`,
      metrics,
      tableData: data.slice(0, 200),
      tableColumns: config.columns,
      summary: [
        { label: "Report Type", value: type },
        { label: "Total Records", value: data.length },
        { label: "Period", value: options.startDate ? `${new Date(options.startDate).toLocaleDateString("en-GB")} – ${new Date(options.endDate || Date.now()).toLocaleDateString("en-GB")}` : "All time" },
        { label: "Generated", value: new Date().toLocaleDateString("en-GB") },
      ],
    });
  }

  /**
   * Generate a full project PDF report including tasks and members.
   */
  async generateProjectPDF(projectId, tenantId, branding = {}) {
    const [project, tasks, members] = await Promise.all([
      mongoose.model("Project").findOne({ _id: projectId, tenantId }).lean(),
      mongoose.model("Task").find({ projectId, tenantId }).populate("assignedTo", "fullName").lean(),
      mongoose.model("Team").findOne({ projectId }).lean().then(t => t?.members || []).catch(() => []),
    ]);
    if (!project) throw new AppError(HttpStatus.NOT_FOUND, "Project not found", "E4040");
    return generateProjectReport({ project, tasks, members, branding });
  }

  /**
   * Generate a workspace summary PDF.
   */
  async generateWorkspacePDF(workspaceId, tenantId, branding = {}) {
    const [workspace, projects, members, channels] = await Promise.all([
      mongoose.model("Workspace").findOne({ _id: workspaceId, tenantId }).lean(),
      mongoose.model("Project").find({ workspaceId, tenantId }).lean(),
      mongoose.model("Workspace").findOne({ _id: workspaceId }).select("members").lean().then(w => w?.members || []),
      mongoose.model("Channel").find({ workspaceId, tenantId }).lean(),
    ]);
    if (!workspace) throw new AppError(HttpStatus.NOT_FOUND, "Workspace not found", "E4041");
    const tasksCompleted = await mongoose.model("Task").countDocuments({ workspaceId, tenantId, status: "done" }).catch(() => 0);
    return generateWorkspaceSummary({ workspace, projects, members, channels, metrics: { tasksCompleted }, branding });
  }

  /**
   * Generate a ticket report PDF.
   */
  async generateTicketPDF(tenantId, filters = {}, branding = {}) {
    const query = { tenantId };
    if (filters.from) query.createdAt = { $gte: new Date(filters.from) };
    if (filters.to) query.createdAt = { ...(query.createdAt || {}), $lte: new Date(filters.to) };
    const tickets = await mongoose.model("Ticket").find(query).populate("assignee", "fullName").lean();
    return generateTicketReport({ tickets, filters, branding });
  }
}

export const analyticsService = new AnalyticsService();
