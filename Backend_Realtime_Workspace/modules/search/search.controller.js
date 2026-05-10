import BaseController from "../../core/base/base.controller.js";
import { searchService } from "./search.service.js";

class SearchController extends BaseController {
  
  globalSearch = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { q } = req.query;
    const pagination = BaseController.getPagination(req);
    
    const result = await searchService.globalSearch(q, tenantId, pagination);
    return BaseController.sendSuccess(res, result, "Global search completed");
  };

  resourceSearch = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { q } = req.query;
    const { resource } = req.params;
    const pagination = BaseController.getPagination(req);
    
    const result = await searchService.resourceSearch(resource, q, tenantId, pagination);
    return BaseController.sendSuccess(res, result, "Resource search completed");
  };
}

export const searchController = new SearchController();
