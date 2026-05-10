import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Organization from "./models/organization.model.js";
import { AppError } from "../../core/errors/app-error.js";
import { HttpStatus } from "../../config/constants.js";
import { v4 as uuidv4 } from "uuid";

class OrganizationRepository extends BaseRepository {
  constructor() {
    super(Organization, { tenantScoped: false }); // Organizations define the tenant
  }
}

class OrganizationService extends BaseService {
  constructor() {
    super(new OrganizationRepository(), {
      name: "OrganizationService",
      cachePrefix: "org",
      cacheTTL: 3600,
    });
  }

  async createOrganization(data, userId) {
    const { name, slug } = data;
    
    // Check if slug is taken
    const existing = await this.repository.findOne({ slug });
    if (existing) {
      throw new AppError(HttpStatus.CONFLICT, "Organization slug is already taken", "E5001");
    }

    const tenantId = `tnt_${uuidv4().replace(/-/g, "")}`;

    const newOrg = await this.repository.create({
      ...data,
      tenantId,
      owner: userId,
      createdBy: userId,
    });

    this.emit("organization.created", { organizationId: newOrg._id, tenantId });

    return newOrg;
  }

  async getOrganizationById(id) {
    const org = await this.cachedFindById(id);
    if (!org) {
      throw new AppError(HttpStatus.NOT_FOUND, "Organization not found", "E3001");
    }
    return org;
  }

  async updateOrganization(id, updates, userId) {
    const org = await this.getOrganizationById(id);
    
    // Simplistic owner check for now, should be replaced by Zanzibar-style permission engine
    if (org.owner.toString() !== userId.toString()) {
        throw new AppError(HttpStatus.FORBIDDEN, "Only the owner can update the organization", "E4001");
    }

    const updated = await this.updateById(id, updates);
    this.emit("organization.updated", { organizationId: id, updates });
    return updated;
  }

  async updateSettings(id, settings, userId) {
      const org = await this.getOrganizationById(id);
      
      if (org.owner.toString() !== userId.toString()) {
          throw new AppError(HttpStatus.FORBIDDEN, "Only the owner can update the organization", "E4001");
      }

      const updated = await this.updateById(id, { settings: { ...org.settings, ...settings } });
      this.emit("organization.settings_updated", { organizationId: id, settings });
      return updated;
  }
}

export const organizationService = new OrganizationService();
