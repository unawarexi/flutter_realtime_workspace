import BaseController from "../../core/base/base.controller.js";
import { channelService } from "./channel.service.js";

class ChannelController extends BaseController {
  
  createChannel = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const channel = await channelService.createChannel(req.body, tenantId, orgId, userId);
    return BaseController.sendCreated(res, channel, "Channel created successfully");
  };

  getChannels = async (req, res) => {
    const { tenantId, orgId, userId } = BaseController.getContext(req);
    const { workspaceId, type } = req.query;
    
    // For now: find channels the user is a member of, or public channels in the workspace
    const filter = { orgId };
    if (workspaceId) filter.workspaceId = workspaceId;
    if (type) filter.type = type;
    
    const pagination = BaseController.getPagination(req);
    const result = await channelService.paginate(filter, {
      tenantId,
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });

    return BaseController.sendPaginated(res, result, "Channels retrieved");
  };

  getChannelById = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const channel = await channelService.getChannelById(req.params.id, tenantId);
    return BaseController.sendSuccess(res, channel, "Channel retrieved");
  };

  updateChannel = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const channel = await channelService.updateChannel(req.params.id, req.body, tenantId);
    return BaseController.sendSuccess(res, channel, "Channel updated");
  };

  deleteChannel = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    await channelService.deleteById(req.params.id, { tenantId });
    return BaseController.sendSuccess(res, null, "Channel deleted");
  };

  addMember = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { userId, role } = req.body;
    const channel = await channelService.addMember(req.params.id, userId, role, tenantId);
    return BaseController.sendSuccess(res, channel, "Member added");
  };

  removeMember = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { memberId } = req.params;
    const channel = await channelService.removeMember(req.params.id, memberId, tenantId);
    return BaseController.sendSuccess(res, channel, "Member removed");
  };

  // --- Messages ---
  getMessages = async (req, res) => {
    const { tenantId } = BaseController.getContext(req);
    const { threadId } = req.query;
    const filter = { deleted: false };
    if (threadId) {
        filter.threadId = threadId;
    } else {
        filter.threadId = { $exists: false }; // Main channel messages
    }

    const pagination = BaseController.getPagination(req);
    const result = await channelService.getMessages(req.params.id, filter, pagination, tenantId);
    return BaseController.sendPaginated(res, result, "Messages retrieved");
  };

  sendMessage = async (req, res) => {
    const { tenantId, userId } = BaseController.getContext(req);
    const files = req.files || [];
    const message = await channelService.sendMessage(
      req.params.id, 
      userId, 
      req.body.content, 
      req.body.threadId, 
      tenantId, 
      files
    );
    return BaseController.sendCreated(res, message, "Message sent");
  };
}

export const channelController = new ChannelController();
