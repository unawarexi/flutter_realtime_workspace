// ============================================================================
// TeamSpot — Storage Service
// Cloudinary file upload/management, per-tenant asset tracking
// Files are stored in Cloudinary; metadata is persisted in MongoDB Asset model
// ============================================================================

import crypto from "crypto";
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Asset from "./models/asset.model.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";
import { notFound, badRequest } from "../../core/errors/app-error.js";
import { RabbitQueues, KafkaTopics } from "../../config/constants.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("StorageService");

class AssetRepository extends BaseRepository {
  constructor() {
    super(Asset, { tenantScoped: true });
  }
}

class StorageService extends BaseService {
  constructor() {
    super(new AssetRepository(), {
      name: "StorageService",
      cachePrefix: "asset",
      cacheTTL: 60,
    });
  }

  // ── Upload single file ───────────────────────────────────────────────────────
  async uploadFile({ tenantId, userId, file, attachTo, folder = "general" }) {
    if (!file?.buffer) throw badRequest("No file provided");

    const tenantFolder = `teamspot/${tenantId}/${folder}`;
    const publicId     = `${tenantFolder}/${crypto.randomUUID()}`;

    const uploaded = await uploadBuffer(file.buffer, {
      folder:       tenantFolder,
      publicId,
      resourceType: "auto",
    });

    const asset = await this.repository.create({
      tenantId,
      uploadedBy:   userId,
      filename:     publicId,
      originalName: file.originalname,
      mimeType:     file.mimetype,
      bytes:        uploaded.bytes || file.size,
      url:          uploaded.url,
      publicId:     uploaded.publicId,
      resourceType: uploaded.resourceType || deriveResourceType(file.mimetype),
      folder,
      thumbnailUrl: uploaded.thumbnailUrl || null,
      attachedTo:   attachTo || undefined,
      status:       "ready",
    });

    await publishEvent(KafkaTopics.STORAGE_EVENTS, tenantId, {
      type: "asset.uploaded",
      assetId: asset._id,
      tenantId, userId,
      bytes: asset.bytes,
    });

    return asset;
  }

  // ── Upload multiple files ────────────────────────────────────────────────────
  async uploadMultiple({ tenantId, userId, files, folder = "general" }) {
    if (!files?.length) throw badRequest("No files provided");

    const results = await Promise.all(
      files.map((file) => this.uploadFile({ tenantId, userId, file, folder }))
    );
    return results;
  }

  // ── List assets ──────────────────────────────────────────────────────────────
  async listAssets({ tenantId, userId, folder, resourceType, attachedToType, attachedToId, page = 1, limit = 20 }) {
    const filter = { tenantId, status: { $ne: "deleted" } };
    if (userId)        filter.uploadedBy    = userId;
    if (folder)        filter.folder        = folder;
    if (resourceType)  filter.resourceType  = resourceType;
    if (attachedToType && attachedToId) {
      filter["attachedTo.type"] = attachedToType;
      filter["attachedTo.id"]   = attachedToId;
    }

    return this.repository.paginate({ filter, page, limit, sort: { createdAt: -1 } }, { tenantId });
  }

  // ── Get single asset ─────────────────────────────────────────────────────────
  async getAsset({ id, tenantId }) {
    const asset = await this.repository.findById(id, { tenantId });
    if (!asset || asset.status === "deleted") throw notFound("Asset");
    return asset;
  }

  // ── Delete asset ─────────────────────────────────────────────────────────────
  async deleteAsset({ id, tenantId, userId }) {
    const asset = await this.repository.findById(id, { tenantId });
    if (!asset || asset.status === "deleted") throw notFound("Asset");

    // Delete from Cloudinary
    try {
      await deleteFile(asset.publicId);
    } catch (err) {
      log.warn({ assetId: id, err: err.message }, "Cloudinary delete failed — marking soft-deleted anyway");
    }

    await this.repository.updateById(id, { status: "deleted", deletedAt: new Date() }, { tenantId });

    await publishToQueue(RabbitQueues.CLEANUP, {
      action: "asset.delete",
      assetId: id,
      publicId: asset.publicId,
      tenantId,
    });

    return { message: "Asset deleted" };
  }

  // ── Attach asset to an entity ─────────────────────────────────────────────────
  async attachAsset({ id, tenantId, attachedToType, attachedToId }) {
    const asset = await this.repository.findById(id, { tenantId });
    if (!asset) throw notFound("Asset");
    await this.repository.updateById(id, { attachedTo: { type: attachedToType, id: attachedToId } }, { tenantId });
    return { message: "Asset attached" };
  }
}

// ── Derive resource type from MIME type ──────────────────────────────────────
function deriveResourceType(mimeType = "") {
  if (mimeType.startsWith("image/"))       return "image";
  if (mimeType.startsWith("video/"))       return "video";
  if (mimeType.startsWith("audio/"))       return "audio";
  if (mimeType.includes("pdf") || mimeType.includes("document") || mimeType.includes("text")) return "document";
  return "raw";
}

export const storageService = new StorageService();
