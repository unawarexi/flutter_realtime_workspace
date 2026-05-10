import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import User from "./models/user.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer } from "../../infrastructure/storage/cloudinary.service.js";

class UserRepository extends BaseRepository {
  constructor() {
    // Users are partially tenant-scoped, but mostly global entity in Firebase
    super(User, { tenantScoped: false });
  }
}

class UserService extends BaseService {
  constructor() {
    super(new UserRepository(), {
      name: "UserService",
      cachePrefix: "user",
      cacheTTL: 3600,
    });
  }

  async getMyProfile(firebaseUid) {
    const user = await this.repository.findOne({ firebaseUid });
    if (!user) {
      throw new AppError(HttpStatus.NOT_FOUND, "User profile not found", "E3004");
    }
    return user;
  }

  async updateMyProfile(firebaseUid, updates) {
    const user = await this.getMyProfile(firebaseUid);
    const updated = await this.updateById(user._id, updates);
    this.emit("user.profile_updated", { userId: user._id });
    return updated;
  }

  async uploadProfilePicture(firebaseUid, fileBuffer) {
    const user = await this.getMyProfile(firebaseUid);
    
    const result = await uploadBuffer(fileBuffer, {
      folder: "teamspot/profiles",
      resourceType: "image",
    });

    const updated = await this.updateById(user._id, { profilePicture: result.url });
    this.emit("user.picture_updated", { userId: user._id, url: result.url });
    return updated;
  }

  async deleteMyProfile(firebaseUid) {
    const user = await this.getMyProfile(firebaseUid);
    // Soft delete
    await this.updateById(user._id, { deletedAt: new Date(), status: "deactivated" });
    this.emit("user.deleted", { userId: user._id });
    return true;
  }
}

export const userService = new UserService();
