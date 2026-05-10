import BaseController from "../../core/base/base.controller.js";
import { whiteboardService } from "./whiteboard.service.js";

class WhiteboardController extends BaseController {
  
  createWhiteboard = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const wb = await whiteboardService.createWhiteboard(req.body, tenantId, userId);
    return BaseController.sendCreated(res, wb, "Whiteboard created successfully");
  };

  getWhiteboards = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const pagination = BaseController.getPagination(req);
    const result = await whiteboardService.paginate({}, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });
    return BaseController.sendPaginated(res, result, "Whiteboards retrieved");
  };

  getWhiteboardById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const wb = await whiteboardService.findById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, wb, "Whiteboard retrieved");
  };

  updateWhiteboard = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const wb = await whiteboardService.updateById(req.params.id, req.body, { tenantId });
    return BaseController.sendSuccess(res, wb, "Whiteboard updated");
  };

  updateState = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const wb = await whiteboardService.updateState(req.params.id, req.body.state, tenantId);
    return BaseController.sendSuccess(res, wb, "Whiteboard state updated");
  };

  deleteWhiteboard = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await whiteboardService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Whiteboard deleted");
  };
}

export const whiteboardController = new WhiteboardController();
