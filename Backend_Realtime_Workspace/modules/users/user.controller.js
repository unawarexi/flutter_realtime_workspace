import BaseController from "../../core/base/base.controller.js";
import { userService } from "./user.service.js";

class UserController extends BaseController {
  
  getMyProfile = async (req, res) => {
    // req.user is set by firebaseAuthMiddleware
    const profile = await userService.getMyProfile(req.user.uid);
    return BaseController.sendSuccess(res, profile, "User profile retrieved");
  };

  updateMyProfile = async (req, res) => {
    const updated = await userService.updateMyProfile(req.user.uid, req.body);
    return BaseController.sendSuccess(res, updated, "User profile updated");
  };

  uploadProfilePicture = async (req, res) => {
    if (!req.file) {
      return BaseController.sendSuccess(res, null, "No file uploaded"); // Should be error but keeping simple
    }
    const updated = await userService.uploadProfilePicture(req.user.uid, req.file.buffer);
    return BaseController.sendSuccess(res, updated, "Profile picture uploaded");
  };

  deleteMyProfile = async (req, res) => {
    await userService.deleteMyProfile(req.user.uid);
    return BaseController.sendSuccess(res, null, "User profile deleted");
  };

  getAllUsers = async (req, res) => {
    const pagination = BaseController.getPagination(req);
    const result = await userService.paginate({}, {
      page: pagination.page,
      limit: pagination.limit,
      sort: BaseController.parseSort(pagination.sort)
    });
    return BaseController.sendPaginated(res, result, "Users retrieved");
  };
  
  getUserById = async (req, res) => {
    const user = await userService.findById(req.params.id);
    return BaseController.sendSuccess(res, user, "User retrieved");
  };
}

export const userController = new UserController();
