import { asyncHandler } from "../../core/base/base.controller.js";
import { searchModuleService } from "./search.service.js";
import { success } from "../../core/utils/api-response.js";

const ctx = (req) => ({
  tenantId: req.tenant?.id || req.user?.tenantId,
  userId:   req.user?._id?.toString() || req.user?.id,
});

export const globalSearch = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await searchModuleService.globalSearch({ ...req.query, query: req.query.q, tenantId, userId });
  return success(res, result, "Search completed");
});

export const resourceSearch = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const result = await searchModuleService.resourceSearch({
    resource: req.params.resource, query: req.query.q, tenantId, userId, ...req.query,
  });
  return success(res, result, "Resource search completed");
});

export const getSuggestions = asyncHandler(async (req, res) => {
  const { tenantId } = ctx(req);
  const suggestions = await searchModuleService.getSuggestions({ query: req.query.q, tenantId });
  return success(res, suggestions, "Suggestions retrieved");
});

export const getRecentSearches = asyncHandler(async (req, res) => {
  const { tenantId, userId } = ctx(req);
  const recent = await searchModuleService.getRecentSearches({ tenantId, userId });
  return success(res, recent, "Recent searches retrieved");
});

export const searchController = { globalSearch, resourceSearch, getSuggestions, getRecentSearches };
