// ============================================================================
// TeamSpot — Base Repository
// Generic Mongoose CRUD with automatic tenantId scoping, soft deletes,
// pagination, and caching support
// ============================================================================

import { PaginationDefaults } from "../../config/constants.js";
import { createLogger } from "../../observability/logger.js";

const log = createLogger("BaseRepository");

export class BaseRepository {
  /**
   * @param {import('mongoose').Model} model — Mongoose model
   * @param {Object} [options]
   * @param {boolean} [options.tenantScoped=true] — auto-scope queries by tenantId
   * @param {boolean} [options.softDelete=false] — use deletedAt instead of remove
   */
  constructor(model, options = {}) {
    this.model = model;
    this.tenantScoped = options.tenantScoped ?? true;
    this.softDelete = options.softDelete ?? false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SCOPE HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  _scopeFilter(filter, tenantId) {
    const scoped = { ...filter };
    if (this.tenantScoped && tenantId) {
      scoped.tenantId = tenantId;
    }
    if (this.softDelete) {
      scoped.deletedAt = { $exists: false };
    }
    return scoped;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────────────────────────────────

  async create(data, { tenantId } = {}) {
    const doc = this.tenantScoped && tenantId ? { ...data, tenantId } : data;
    return this.model.create(doc);
  }

  async createMany(items, { tenantId } = {}) {
    const docs = this.tenantScoped && tenantId
      ? items.map((item) => ({ ...item, tenantId }))
      : items;
    return this.model.insertMany(docs);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // READ
  // ──────────────────────────────────────────────────────────────────────────

  async findById(id, { tenantId, select, populate } = {}) {
    let query = this.model.findOne(this._scopeFilter({ _id: id }, tenantId));
    if (select) query = query.select(select);
    if (populate) query = query.populate(populate);
    return query.lean();
  }

  async findOne(filter, { tenantId, select, populate } = {}) {
    let query = this.model.findOne(this._scopeFilter(filter, tenantId));
    if (select) query = query.select(select);
    if (populate) query = query.populate(populate);
    return query.lean();
  }

  async findMany(filter, { tenantId, select, populate, sort, limit } = {}) {
    let query = this.model.find(this._scopeFilter(filter, tenantId));
    if (select) query = query.select(select);
    if (populate) query = query.populate(populate);
    if (sort) query = query.sort(sort);
    if (limit) query = query.limit(limit);
    return query.lean();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PAGINATED READ (offset-based)
  // ──────────────────────────────────────────────────────────────────────────

  async paginate(filter, { tenantId, page, limit, sort, select, populate } = {}) {
    const pageNum = Math.max(1, parseInt(page, 10) || PaginationDefaults.PAGE);
    const limitNum = Math.min(
      parseInt(limit, 10) || PaginationDefaults.LIMIT,
      PaginationDefaults.MAX_LIMIT
    );
    const skip = (pageNum - 1) * limitNum;
    const scopedFilter = this._scopeFilter(filter, tenantId);

    const [data, total] = await Promise.all([
      (() => {
        let q = this.model.find(scopedFilter).skip(skip).limit(limitNum);
        if (sort) q = q.sort(sort);
        if (select) q = q.select(select);
        if (populate) q = q.populate(populate);
        return q.lean();
      })(),
      this.model.countDocuments(scopedFilter),
    ]);

    return {
      data,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
        hasNextPage: pageNum < Math.ceil(total / limitNum),
        hasPrevPage: pageNum > 1,
      },
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CURSOR-BASED PAGINATION (for infinite scroll / real-time feeds)
  // ──────────────────────────────────────────────────────────────────────────

  async cursorPaginate(filter, { tenantId, cursor, limit, sort = { _id: -1 }, select, populate } = {}) {
    const limitNum = Math.min(
      parseInt(limit, 10) || PaginationDefaults.LIMIT,
      PaginationDefaults.MAX_LIMIT
    );

    const scopedFilter = this._scopeFilter(filter, tenantId);

    if (cursor) {
      const sortField = Object.keys(sort)[0];
      const sortDir = Object.values(sort)[0];
      scopedFilter[sortField] = sortDir === -1 ? { $lt: cursor } : { $gt: cursor };
    }

    let query = this.model.find(scopedFilter).sort(sort).limit(limitNum + 1);
    if (select) query = query.select(select);
    if (populate) query = query.populate(populate);

    const results = await query.lean();
    const hasMore = results.length > limitNum;
    const data = hasMore ? results.slice(0, limitNum) : results;

    const sortField = Object.keys(sort)[0];
    const nextCursor = data.length > 0 ? data[data.length - 1][sortField] : null;

    return { data, nextCursor, hasMore };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────────────────────────────────

  async updateById(id, updates, { tenantId, returnNew = true } = {}) {
    return this.model.findOneAndUpdate(
      this._scopeFilter({ _id: id }, tenantId),
      updates,
      { new: returnNew, runValidators: true }
    ).lean();
  }

  async updateOne(filter, updates, { tenantId, returnNew = true } = {}) {
    return this.model.findOneAndUpdate(
      this._scopeFilter(filter, tenantId),
      updates,
      { new: returnNew, runValidators: true }
    ).lean();
  }

  async updateMany(filter, updates, { tenantId } = {}) {
    return this.model.updateMany(
      this._scopeFilter(filter, tenantId),
      updates,
      { runValidators: true }
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────────────────────────────────

  async deleteById(id, { tenantId } = {}) {
    if (this.softDelete) {
      return this.model.findOneAndUpdate(
        this._scopeFilter({ _id: id }, tenantId),
        { deletedAt: new Date(), deletedBy: tenantId },
        { new: true }
      ).lean();
    }
    return this.model.findOneAndDelete(
      this._scopeFilter({ _id: id }, tenantId)
    ).lean();
  }

  async deleteMany(filter, { tenantId } = {}) {
    if (this.softDelete) {
      return this.model.updateMany(
        this._scopeFilter(filter, tenantId),
        { deletedAt: new Date() }
      );
    }
    return this.model.deleteMany(this._scopeFilter(filter, tenantId));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AGGREGATION & COUNTING
  // ──────────────────────────────────────────────────────────────────────────

  async count(filter, { tenantId } = {}) {
    return this.model.countDocuments(this._scopeFilter(filter, tenantId));
  }

  async exists(filter, { tenantId } = {}) {
    const doc = await this.model.findOne(this._scopeFilter(filter, tenantId)).select("_id").lean();
    return !!doc;
  }

  async aggregate(pipeline, { tenantId } = {}) {
    if (this.tenantScoped && tenantId) {
      pipeline.unshift({ $match: { tenantId } });
    }
    return this.model.aggregate(pipeline);
  }
}

export default BaseRepository;
