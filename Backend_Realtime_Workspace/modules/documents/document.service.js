// ============================================================================
// TeamSpot — Document Service
// Full Kafka + RabbitMQ AI RAG indexing + PDF render + WebSocket integration
// ============================================================================
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Document from "./models/document.model.js";
import { notFound, forbidden } from "../../core/errors/app-error.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { uploadBuffer, deleteFile } from "../../infrastructure/storage/cloudinary.service.js";
import { KafkaTopics, RabbitQueues, SocketEvents } from "../../config/constants.js";
import { dispatchParseJob, dispatchRenderJob } from "../../infrastructure/pdf/document-job.service.js";
import path from "path";

const EXT_TYPE_MAP = {
  pdf: "pdf", docx: "docx", xlsx: "xlsx", pptx: "pptx",
  jpg: "image", jpeg: "image", png: "image", gif: "image",
  mp4: "video", mp3: "audio", md: "markdown", txt: "text", csv: "csv",
};

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

  // ── Upload ──────────────────────────────────────────────────────────────────

  async uploadDocument(data, file, tenantId, orgId, userId) {
    if (!file) throw notFound("File is required");

    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/documents/${tenantId}`,
      resourceType: "auto",
    });

    const ext = path.extname(file.originalname).substring(1).toLowerCase();
    const docType = EXT_TYPE_MAP[ext] || "other";

    const newDoc = await this.repository.create(
      {
        ...data,
        title: data.title || file.originalname,
        tenantId,
        orgId,
        uploadedBy: userId,
        type: docType,
        file: {
          url: uploadResult.url,
          publicId: uploadResult.publicId,
          filename: file.originalname,
          mimeType: file.mimetype,
          bytes: uploadResult.bytes,
        },
        version: 1,
        versions: [
          {
            version: 1,
            url: uploadResult.url,
            uploadedAt: new Date(),
            uploadedBy: userId,
          },
        ],
      },
      { tenantId }
    );

    // Kafka — storage event
    await publishEvent(KafkaTopics.STORAGE_EVENTS, tenantId, {
      type: "document.uploaded",
      documentId: newDoc._id,
      tenantId,
      uploadedBy: userId,
      docType,
    });

    // RabbitMQ — AI RAG ingestion (via document job service — tracked + cached)
    await dispatchParseJob({
      documentId: newDoc._id.toString(),
      tenantId,
      orgId,
      url: uploadResult.url,
      filename: file.originalname,
      mimeType: file.mimetype,
      docType,
    }, { userId });

    // RabbitMQ — PDF preview render (only for PDFs and Office docs)
    if (["pdf", "docx", "xlsx", "pptx"].includes(docType)) {
      await dispatchRenderJob(
        { templateName: "pdf-base", data: { DOCUMENT_TITLE: data.title || file.originalname, DOCUMENT_SUBTITLE: `${docType.toUpperCase()} Document` } },
        { tenantId, userId, documentId: newDoc._id.toString(), label: "preview" },
      );
    }

    // Audit
    await publishToQueue(RabbitQueues.AUDIT, {
      action: "document.uploaded",
      resourceType: "document",
      resourceId: newDoc._id,
      actor: { id: userId },
      tenantId,
      metadata: { filename: file.originalname, docType },
    });

    return newDoc;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  async getDocumentById(id, tenantId) {
    const doc = await this.cachedFindById(id, { tenantId });
    if (!doc) throw notFound("Document");
    return doc;
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  async updateDocument(id, updates, tenantId, userId) {
    const updated = await this.updateById(id, updates, { tenantId });

    await publishEvent(KafkaTopics.STORAGE_EVENTS, tenantId, {
      type: "document.updated",
      documentId: id,
      tenantId,
      updatedBy: userId,
    });

    return updated;
  }

  // ── New Version Upload ───────────────────────────────────────────────────────

  async uploadNewVersion(id, file, tenantId, userId) {
    const doc = await this.getDocumentById(id, tenantId);

    const uploadResult = await uploadBuffer(file.buffer, {
      folder: `teamspot/documents/${tenantId}`,
      resourceType: "auto",
    });

    const newVersion = doc.version + 1;

    const updated = await this.updateById(
      id,
      {
        "file.url": uploadResult.url,
        "file.publicId": uploadResult.publicId,
        "file.bytes": uploadResult.bytes,
        "file.filename": file.originalname,
        version: newVersion,
        $push: {
          versions: {
            version: newVersion,
            url: uploadResult.url,
            uploadedAt: new Date(),
            uploadedBy: userId,
          },
        },
        indexed: false, // needs re-indexing
      },
      { tenantId }
    );

    // Trigger re-indexing for the new version
    await publishToQueue(RabbitQueues.AI_RAG_INGEST, {
      documentId: id,
      tenantId,
      url: uploadResult.url,
      filename: file.originalname,
      mimeType: file.mimetype,
      docType: doc.type,
      version: newVersion,
    });

    await publishEvent(KafkaTopics.STORAGE_EVENTS, tenantId, {
      type: "document.version_uploaded",
      documentId: id,
      tenantId,
      version: newVersion,
      uploadedBy: userId,
    });

    return updated;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  async deleteDocument(id, tenantId, userId) {
    const doc = await this.getDocumentById(id, tenantId);

    if (doc.uploadedBy.toString() !== userId) {
      throw forbidden("Only the uploader can delete this document");
    }

    // Soft delete
    await this.updateById(id, { status: "deleted", deletedAt: new Date() }, { tenantId });

    // Async Cloudinary cleanup
    if (doc.file?.publicId) {
      await deleteFile(doc.file.publicId).catch((err) =>
        console.error("[Document] Cloudinary delete failed:", err.message)
      );
    }

    await publishEvent(KafkaTopics.STORAGE_EVENTS, tenantId, {
      type: "document.deleted",
      documentId: id,
      tenantId,
      deletedBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "document.deleted",
      resourceType: "document",
      resourceId: id,
      actor: { id: userId },
      tenantId,
    });
  }

  // ── Share ───────────────────────────────────────────────────────────────────

  async shareDocument(id, targetUserId, permission, tenantId, sharedByUserId) {
    const doc = await this.getDocumentById(id, tenantId);

    // Prevent duplicate shares
    const alreadyShared = (doc.sharedWith || []).some(
      (s) => s.userId.toString() === targetUserId
    );

    if (alreadyShared) {
      // Update permission instead
      await this.updateById(
        id,
        { $set: { "sharedWith.$[s].permission": permission || "view" } },
        { tenantId, arrayFilters: [{ "s.userId": targetUserId }] }
      );
    } else {
      await this.updateById(
        id,
        { $push: { sharedWith: { userId: targetUserId, permission: permission || "view" } } },
        { tenantId }
      );
    }

    // Notify recipient via WebSocket + Email
    emitToUser(targetUserId, SocketEvents.NOTIFICATION, {
      type: "document.shared",
      documentId: id,
      title: doc.title,
      permission: permission || "view",
      sharedBy: sharedByUserId,
    });

    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      userId: targetUserId,
      templateName: "documentShared",
      templateData: {
        documentTitle: doc.title,
        permission: permission || "view",
        sharedBy: sharedByUserId,
      },
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "document.shared",
      resourceType: "document",
      resourceId: id,
      actor: { id: sharedByUserId },
      tenantId,
      metadata: { targetUserId, permission },
    });

    return { documentId: id, sharedWith: targetUserId };
  }

  // ── Mark Indexed ─────────────────────────────────────────────────────────────
  // Called by AI worker after successful RAG ingestion

  async markIndexed(id, tenantId, embeddingIds, chunkCount) {
    return this.updateById(
      id,
      { indexed: true, indexedAt: new Date(), embeddingIds, chunkCount },
      { tenantId }
    );
  }
}

export const documentService = new DocumentService();
