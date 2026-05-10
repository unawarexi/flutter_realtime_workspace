import BaseController from "../../core/base/base.controller.js";
import { documentService } from "./document.service.js";

class DocumentController extends BaseController {
  
  uploadDocument = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const doc = await documentService.uploadDocument(req.body, req.file, tenantId, orgId, userId);
    return BaseController.sendCreated(res, doc, "Document uploaded successfully");
  };

  getDocuments = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const { workspaceId, projectId, type } = req.query;
    
    const filter = { orgId };
    if (workspaceId) filter.workspaceId = workspaceId;
    if (projectId) filter.projectId = projectId;
    if (type) filter.type = type;

    // Visibility filtering
    filter.$or = [
      { uploadedBy: userId },
      { visibility: "public" },
      { visibility: "organization" },
      { "sharedWith.userId": userId }
    ];
    if (workspaceId) {
        filter.$or.push({ visibility: "workspace", workspaceId });
    }
    
    const pagination = BaseController.getPagination(req);
    const result = await documentService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Documents retrieved");
  };

  getDocumentById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const doc = await documentService.getDocumentById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, doc, "Document retrieved");
  };

  updateDocument = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const doc = await documentService.updateDocument(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, doc, "Document updated");
  };

  deleteDocument = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await documentService.deleteDocument(req.params.id, tenantId);
    return BaseController.sendSuccess(res, null, "Document deleted");
  };

  shareDocument = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { userId, permission } = req.body;
    const doc = await documentService.shareDocument(req.params.id, userId, permission, tenantId);
    return BaseController.sendSuccess(res, doc, "Document shared");
  };
}

export const documentController = new DocumentController();
