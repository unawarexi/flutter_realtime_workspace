import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Document from "./models/document.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";
import path from "path";

class DocumentRepository extends BaseRepository {
  constructor() {
    super(Document, { tenantScoped: true });
  }
}

class DocumentService extends BaseService {
  constructor() {
    super(new DocumentRepository(), {
      name: "DocumentService",
      cachePrefix: "doc",
      cacheTTL: 1800,
    });
  }

  async uploadDocument(data, file, tenantId, orgId, userId) {
    if (!file) throw new AppError(HttpStatus.BAD_REQUEST, "File is required", "E4007");

    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/documents/${tenantId}`,
      resourceType: "auto"
    });

    const ext = path.extname(file.originalname).substring(1).toLowerCase();
    const typeMap = {
        pdf: "pdf", docx: "docx", xlsx: "xlsx", pptx: "pptx",
        jpg: "image", jpeg: "image", png: "image", gif: "image",
        mp4: "video", mp3: "audio", md: "markdown", txt: "text", csv: "csv"
    };

    const docType = typeMap[ext] || "other";

    const newDoc = await this.repository.create({
      ...data,
      tenantId,
      orgId,
      uploadedBy: userId,
      type: docType,
      file: {
        url: uploadResult.url,
        publicId: uploadResult.publicId,
        filename: file.originalname,
        mimeType: file.mimetype,
        bytes: uploadResult.bytes
      }
    }, { tenantId });

    this.emit("document.uploaded", { documentId: newDoc._id, tenantId, orgId });
    // This event should be picked up by the AI service to parse/index the document
    this.emit("document.needs_indexing", { documentId: newDoc._id, tenantId });

    return newDoc;
  }

  async getDocumentById(id, tenantId) {
    const doc = await this.cachedFindById(id, { tenantId });
    if (!doc) throw new AppError(HttpStatus.NOT_FOUND, "Document not found", "E3014");
    return doc;
  }

  async updateDocument(id, updates, tenantId) {
    const updated = await this.updateById(id, updates, { tenantId });
    this.emit("document.updated", { documentId: id, tenantId });
    return updated;
  }

  async deleteDocument(id, tenantId) {
    const doc = await this.getDocumentById(id, tenantId);
    
    // Attempt to delete from cloudinary if not soft deleted
    if (doc.file && doc.file.publicId) {
        await deleteFile(doc.file.publicId).catch(err => console.error(err));
    }

    await this.deleteById(id, { tenantId });
    this.emit("document.deleted", { documentId: id, tenantId });
    return true;
  }

  async shareDocument(id, targetUserId, permission, tenantId) {
    const updated = await this.updateById(id, {
        $push: { sharedWith: { userId: targetUserId, permission: permission || 'view' } }
    }, { tenantId });
    
    return updated;
  }
}

export const documentService = new DocumentService();
