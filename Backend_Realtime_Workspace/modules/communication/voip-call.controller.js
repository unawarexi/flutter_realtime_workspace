// ============================================================================
// TeamSpot — VoIP Call Controller
// ============================================================================

import { VoipCallService } from "./voip-call.service.js";
import { success, created } from "../../core/utils/api-response.js";
import { asyncHandler } from "../../core/base/base.controller.js";

const voipService = new VoipCallService();

// POST /communication/calls/initiate
export const initiateCall = asyncHandler(async (req, res) => {
  const { calleeId, type } = req.body;
  const result = await voipService.initiateCall({
    callerId: req.user.uid,
    calleeId,
    type,
    tenantId: req.tenant?.tenantId,
  });
  return created(res, result, "Call initiated");
});

// PUT /communication/calls/:id/accept
export const acceptCall = asyncHandler(async (req, res) => {
  const result = await voipService.acceptCall({
    callId: req.params.id,
    calleeId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, result, "Call accepted");
});

// PUT /communication/calls/:id/end
export const endCall = asyncHandler(async (req, res) => {
  const result = await voipService.endCall({
    callId: req.params.id,
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, result, "Call ended");
});

// PUT /communication/calls/:id/reject
export const rejectCall = asyncHandler(async (req, res) => {
  const result = await voipService.rejectCall({
    callId: req.params.id,
    calleeId: req.user.uid,
    tenantId: req.tenant?.tenantId,
  });
  return success(res, result, "Call rejected");
});

// GET /communication/calls/history
export const getCallHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const calls = await voipService.getCallHistory({
    userId: req.user.uid,
    tenantId: req.tenant?.tenantId,
    page: Number(page),
    limit: Number(limit),
  });
  return success(res, calls);
});
