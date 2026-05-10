import BaseController from "../../core/base/base.controller.js";
import { adminService } from "./admin.service.js";

class AdminController extends BaseController {
  
  getTenants = async (req, res) => {
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;
    
    const pagination = BaseController.getPagination(req);
    const result = await adminService.getTenants(filter, pagination);

    return BaseController.sendPaginated(res, result, "Tenants retrieved");
  };

  updateTenantStatus = async (req, res) => {
    const adminUserId = req.user.uid;
    const org = await adminService.updateTenantStatus(req.params.id, req.body.status, adminUserId);
    return BaseController.sendSuccess(res, org, "Tenant status updated");
  };

  getSystemStats = async (req, res) => {
    const stats = await adminService.getSystemStats();
    return BaseController.sendSuccess(res, stats, "System stats retrieved");
  };

  impersonateUser = async (req, res) => {
    const adminUserId = req.user.uid;
    const result = await adminService.generateImpersonationToken(adminUserId, req.body.userId);
    return BaseController.sendSuccess(res, result, "Impersonation session created");
  };
}

export const adminController = new AdminController();
