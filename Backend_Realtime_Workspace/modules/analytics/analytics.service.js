import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import mongoose from "mongoose";
import { createLogger } from "../../observability/logger.js";
import { generateCSV, generateXLSX, generateBrandedPDF } from "./report-gen-analytics.controller.js";

const log = createLogger("AnalyticsService");

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
      const [projectsCount, tasksCount, usersCount, meetingsCount] = await Promise.all([
        mongoose.model("Project").countDocuments(query),
        mongoose.model("Task").countDocuments(query),
        mongoose.model("User").countDocuments(query),
        mongoose.model("Meeting").countDocuments(query)
      ]);

      return {
        projects: projectsCount,
        tasks: tasksCount,
        users: usersCount,
        meetings: meetingsCount
      };
    } catch (error) {
      log.error("Failed to aggregate dashboard stats", { error, tenantId });
      throw new AppError(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to aggregate statistics", "E5000");
    }
  }

  async generateReport(type, format, tenantId, options = {}) {
    // Collect data based on type
    let data = [];
    let columns = [];
    let title = `${type.toUpperCase()} Report`;

    if (type === 'tasks') {
        data = await mongoose.model("Task").find({ tenantId }).lean();
        columns = [
            { header: "Title", key: "title" },
            { header: "Status", key: "status" },
            { header: "Priority", key: "priority" }
        ];
    } else if (type === 'projects') {
        data = await mongoose.model("Project").find({ tenantId }).lean();
        columns = [
            { header: "Name", key: "name" },
            { header: "Status", key: "status" }
        ];
    } else {
        throw new AppError(HttpStatus.BAD_REQUEST, "Unsupported report type", "E4009");
    }

    // Generate output format
    if (format === 'csv') {
        return generateCSV(data, columns);
    } else if (format === 'xlsx') {
        return generateXLSX(data, columns);
    } else if (format === 'pdf') {
        return await generateBrandedPDF(data, columns, title, "TeamSpot Analytics");
    }
    
    throw new AppError(HttpStatus.BAD_REQUEST, "Unsupported format", "E4010");
  }
}

export const analyticsService = new AnalyticsService();
