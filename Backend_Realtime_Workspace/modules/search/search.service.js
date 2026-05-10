import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import mongoose from "mongoose";

class SearchService {
  constructor() {
    // OpenSearch client initialization would go here
    this.name = "SearchService";
  }

  async globalSearch(query, tenantId, options = {}) {
    const { limit = 10, page = 1 } = options;
    const skip = (page - 1) * limit;

    // Placeholder: Multi-collection text search fallback (using mongoose text indexes)
    // In a real OpenSearch implementation, we would query the OpenSearch cluster directly
    
    const results = {
      projects: await mongoose.model("Project").find({ tenantId, $text: { $search: query } }, { score: { $meta: "textScore" } }).sort({ score: { $meta: "textScore" } }).limit(limit).lean(),
      tasks: await mongoose.model("Task").find({ tenantId, $text: { $search: query } }, { score: { $meta: "textScore" } }).sort({ score: { $meta: "textScore" } }).limit(limit).lean(),
      issues: await mongoose.model("Issue").find({ tenantId, $text: { $search: query } }, { score: { $meta: "textScore" } }).sort({ score: { $meta: "textScore" } }).limit(limit).lean(),
      documents: await mongoose.model("Document").find({ tenantId, $text: { $search: query } }, { score: { $meta: "textScore" } }).sort({ score: { $meta: "textScore" } }).limit(limit).lean(),
      users: await mongoose.model("User").find({ tenantId, $text: { $search: query } }, { score: { $meta: "textScore" } }).sort({ score: { $meta: "textScore" } }).limit(limit).lean(),
    };

    return {
      query,
      page,
      limit,
      results
    };
  }

  async resourceSearch(resource, query, tenantId, options = {}) {
    const { limit = 20, page = 1 } = options;
    const skip = (page - 1) * limit;

    const resourceModelMap = {
      "users": "User",
      "projects": "Project",
      "tasks": "Task",
      "issues": "Issue",
      "tickets": "Ticket",
      "documents": "Document",
      "channels": "Channel",
      "messages": "Message"
    };

    const modelName = resourceModelMap[resource];
    if (!modelName) {
      throw new AppError(HttpStatus.BAD_REQUEST, `Invalid resource: ${resource}`, "E4008");
    }

    const Model = mongoose.model(modelName);
    const filter = { tenantId, $text: { $search: query } };
    
    const [data, total] = await Promise.all([
      Model.find(filter, { score: { $meta: "textScore" } })
           .sort({ score: { $meta: "textScore" } })
           .skip(skip)
           .limit(limit)
           .lean(),
      Model.countDocuments(filter)
    ]);

    return {
      data,
      total,
      page,
      limit,
      pages: Math.ceil(total / limit)
    };
  }
}

export const searchService = new SearchService();
