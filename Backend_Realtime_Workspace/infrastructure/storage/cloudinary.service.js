// ============================================================================
// TeamSpot — Cloudinary Storage Service
// Upload/delete with Multer config for file handling
// ============================================================================

import { v2 as cloudinary } from "cloudinary";
import multer from "multer";
import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";
import { StorageConfig } from "../../config/constants.js";
import { allowedExtensions, extensionToMimeType } from "../../core/utils/extentions.js";

// Build allowed MIME type sets from the canonical extensions file
const ALLOWED_IMAGE_TYPES  = new Set(allowedExtensions.images.map((e) => extensionToMimeType[e]).filter(Boolean));
const ALLOWED_VIDEO_TYPES  = new Set(allowedExtensions.videos.map((e) => extensionToMimeType[e]).filter(Boolean));
const ALLOWED_AUDIO_TYPES  = new Set(allowedExtensions.audio.map((e) => extensionToMimeType[e]).filter(Boolean));
const ALLOWED_DOCUMENT_TYPES = new Set(allowedExtensions.documents.map((e) => extensionToMimeType[e]).filter(Boolean));
const ALLOWED_ARCHIVE_TYPES  = new Set(allowedExtensions.archives.map((e) => extensionToMimeType[e]).filter(Boolean));

// All MIME types allowed for upload (images + videos + audio + documents + archives)
const ALL_ALLOWED_MIME_TYPES = new Set([
  ...ALLOWED_IMAGE_TYPES,
  ...ALLOWED_VIDEO_TYPES,
  ...ALLOWED_AUDIO_TYPES,
  ...ALLOWED_DOCUMENT_TYPES,
  ...ALLOWED_ARCHIVE_TYPES,
]);

const log = createLogger("Cloudinary");

// ============================================================================
// INITIALIZATION
// ============================================================================

export function initCloudinary() {
  if (!env.CLOUDINARY_CLOUD_NAME) {
    log.warn("Cloudinary not configured — file uploads disabled");
    return;
  }

  cloudinary.config({
    cloud_name: env.CLOUDINARY_CLOUD_NAME,
    api_key: env.CLOUDINARY_API_KEY,
    api_secret: env.CLOUDINARY_API_SECRET,
  });

  log.success("Cloudinary initialized");
}

// ============================================================================
// UPLOAD / DELETE
// ============================================================================

export async function uploadFile(filePath, options = {}) {
  const result = await cloudinary.uploader.upload(filePath, {
    folder: options.folder || "teamspot",
    resource_type: options.resourceType || "auto",
    transformation: options.transformation || undefined,
    public_id: options.publicId || undefined,
  });

  return {
    publicId: result.public_id,
    url: result.secure_url,
    format: result.format,
    bytes: result.bytes,
    width: result.width,
    height: result.height,
    resourceType: result.resource_type,
  };
}

export async function uploadBuffer(buffer, options = {}) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: options.folder || "teamspot",
        resource_type: options.resourceType || "auto",
        public_id: options.publicId || undefined,
      },
      (error, result) => {
        if (error) reject(error);
        else resolve({
          publicId: result.public_id,
          url: result.secure_url,
          format: result.format,
          bytes: result.bytes,
          width: result.width,
          height: result.height,
          resourceType: result.resource_type,
        });
      }
    );
    stream.end(buffer);
  });
}

export async function deleteFile(publicId) {
  return cloudinary.uploader.destroy(publicId);
}

export async function deleteMultiple(publicIds) {
  return cloudinary.api.delete_resources(publicIds);
}

// ============================================================================
// MULTER CONFIG
// ============================================================================

const storage = multer.memoryStorage();

const fileFilter = (_req, file, cb) => {
  if (ALL_ALLOWED_MIME_TYPES.has(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type "${file.mimetype}" is not allowed`), false);
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: StorageConfig.MAX_FILE_SIZE_MB * 1024 * 1024 },
});

export function multerErrorHandler(err, _req, res, next) {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({
      success: false,
      error: { code: "E2005", message: err.message },
    });
  }
  if (err) {
    return res.status(400).json({
      success: false,
      error: { code: "E2004", message: err.message },
    });
  }
  next();
}

export default {
  initCloudinary, uploadFile, uploadBuffer, deleteFile,
  deleteMultiple, upload, multerErrorHandler,
};

// Named exports so callers can restrict uploads to a specific type
export {
  ALLOWED_IMAGE_TYPES,
  ALLOWED_VIDEO_TYPES,
  ALLOWED_AUDIO_TYPES,
  ALLOWED_DOCUMENT_TYPES,
  ALLOWED_ARCHIVE_TYPES,
  ALL_ALLOWED_MIME_TYPES,
};
