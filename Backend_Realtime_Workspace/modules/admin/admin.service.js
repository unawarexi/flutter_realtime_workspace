import BaseService from "../../core/base/base.service.js";
import mongoose from "mongoose";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { auditService } from "../audit/audit.service.js";

class AdminService extends BaseService {
  constructor() {
    // We don't use a specific model here as admin interacts with many models
    super(null, { name: "AdminService" });
  }

  async getTenants(filter, pagination) {
    const orgModel = mongoose.model("Organization");
    const skip = (pagination.page - 1) * pagination.limit;
    
    const [data, total] = await Promise.all([
      orgModel.find(filter).skip(skip).limit(pagination.limit).lean(),
      orgModel.countDocuments(filter)
    ]);

    return {
      data,
      total,
      page: pagination.page,
      limit: pagination.limit,
      pages: Math.ceil(total / pagination.limit)
    };
  }

  async updateTenantStatus(id, status, adminUserId) {
    const orgModel = mongoose.model("Organization");
    const updated = await orgModel.findByIdAndUpdate(id, { status }, { new: true });
    
    if (!updated) {
      throw new AppError(HttpStatus.NOT_FOUND, "Tenant not found", "E3017");
    }

    // Log this highly sensitive action
    await auditService.logAction({
      action: "tenant_status_updated",
      category: "admin",
      target: { type: "organization", id, name: updated.name },
      changes: { after: { status } }
    }, updated.tenantId, { userId: adminUserId });

    return updated;
  }

  async getSystemStats() {
    const [orgs, users, projects, tasks] = await Promise.all([
      mongoose.model("Organization").countDocuments(),
      mongoose.model("User").countDocuments(),
      mongoose.model("Project").countDocuments(),
      mongoose.model("Task").countDocuments()
    ]);

    return { orgs, users, projects, tasks };
  }

  async generateImpersonationToken(adminUserId, targetUserId) {
    const userModel = mongoose.model("User");
    const targetUser = await userModel.findById(targetUserId);
    
    if (!targetUser) {
      throw new AppError(HttpStatus.NOT_FOUND, "Target user not found", "E3018");
    }

    // In a real implementation, we would generate a custom JWT here
    // with an "impersonator" claim
    
    await auditService.logAction({
      action: "user_impersonated",
      category: "admin",
      target: { type: "user", id: targetUserId, name: targetUser.email },
    }, targetUser.tenantId, { userId: adminUserId });

    return {
      message: "Impersonation token would be generated here",
      targetUser: {
        id: targetUser._id,
        email: targetUser.email,
        tenantId: targetUser.tenantId
      }
    };
  }
}

export const adminService = new AdminService();
