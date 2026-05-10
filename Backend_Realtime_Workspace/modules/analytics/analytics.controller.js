import BaseController from "../../core/base/base.controller.js";
import { analyticsService } from "./analytics.service.js";

class AnalyticsController extends BaseController {
  
  getDashboardStats = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { startDate, endDate, type } = req.query;
    
    const stats = await analyticsService.getDashboardStats(tenantId, { startDate, endDate, type });
    return BaseController.sendSuccess(res, stats, "Dashboard stats retrieved");
  };

  generateReport = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { type, format } = req.query;
    
    const buffer = await analyticsService.generateReport(type, format, tenantId, req.query);
    
    const contentTypeMap = {
        'csv': 'text/csv',
        'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'pdf': 'application/pdf'
    };

    res.setHeader('Content-Type', contentTypeMap[format]);
    res.setHeader('Content-Disposition', `attachment; filename="${type}_report.${format}"`);
    res.status(200).send(buffer);
  };
}

export const analyticsController = new AnalyticsController();
