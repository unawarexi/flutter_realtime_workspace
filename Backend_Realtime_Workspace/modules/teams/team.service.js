// ============================================================================
// TeamSpot — Team Service
// Full Kafka + RabbitMQ + WebSocket + Redis invite-token integration
// ============================================================================
import { randomUUID } from "crypto";
import BaseService from "../../core/base/base.service.js";
import BaseRepository from "../../core/base/base.repository.js";
import Team from "./models/team.model.js";
import { notFound, forbidden, conflict } from "../../core/errors/app-error.js";
import { publishEvent } from "../../infrastructure/kafka/kafka.service.js";
import { publishToQueue } from "../../infrastructure/rabbitmq/rabbitmq.service.js";
import { emitToUser } from "../../infrastructure/websocket/websocket.service.js";
import { getRedisClient } from "../../infrastructure/redis/redis.service.js";
import { KafkaTopics, RabbitQueues, SocketEvents, CacheTTL } from "../../config/constants.js";

const INVITE_TTL = 7 * 24 * 60 * 60; // 7 days in seconds

class TeamRepository extends BaseRepository {
  constructor() {
    super(Team, { tenantScoped: true });
  }
}

class TeamService extends BaseService {
  constructor() {
    super(new TeamRepository(), {
      name: "TeamService",
      cachePrefix: "team",
      cacheTTL: CacheTTL.TEAM_MEMBERS || 300,
    });
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  async createTeam(data, tenantId, userId) {
    const newTeam = await this.repository.create(
      {
        ...data,
        tenantId,
        createdBy: userId,
        members: [{ userId, role: "owner", status: "active", joinedAt: new Date() }],
      },
      { tenantId }
    );

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.created",
      teamId: newTeam._id,
      tenantId,
      createdBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.created",
      resourceType: "team",
      resourceId: newTeam._id,
      actor: { id: userId },
      tenantId,
    });

    return newTeam;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  async getTeamById(id, tenantId) {
    const team = await this.cachedFindById(id, { tenantId });
    if (!team) throw notFound("Team");
    return team;
  }

  async getTeamMembers(id, tenantId) {
    const team = await this.getTeamById(id, tenantId);
    return team.members.filter((m) => m.status === "active");
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  async updateTeam(id, updates, tenantId, userId) {
    const updated = await this.updateById(id, updates, { tenantId });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.updated",
      teamId: id,
      tenantId,
      updatedBy: userId,
    });

    return updated;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  async deleteTeam(id, tenantId, userId) {
    await this.getTeamById(id, tenantId);
    await this.deleteById(id, { tenantId });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.deleted",
      teamId: id,
      tenantId,
      deletedBy: userId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.deleted",
      resourceType: "team",
      resourceId: id,
      actor: { id: userId },
      tenantId,
    });
  }

  // ── Invite ──────────────────────────────────────────────────────────────────

  async inviteMember(id, email, role, message, tenantId, invitedByUserId) {
    const team = await this.getTeamById(id, tenantId);

    // Permission check
    const inviter = team.members.find(
      (m) => m.userId.toString() === invitedByUserId && m.status === "active"
    );
    if (!inviter || !["owner", "admin", "manager"].includes(inviter.role)) {
      throw forbidden("Insufficient permissions to invite members");
    }

    // Duplicate invite check
    const alreadyInvited = (team.invites || []).find(
      (inv) => inv.email === email && inv.status === "pending"
    );
    if (alreadyInvited) throw conflict("Invite already sent to this email");

    // Already a member?
    const existingMember = (team.members || []).find(
      (m) => m.email === email && m.status === "active"
    );
    if (existingMember) throw conflict("User is already a team member");

    // Secure token — stored in Redis for lookup at accept time
    const token = randomUUID();
    const expiresAt = new Date(Date.now() + INVITE_TTL * 1000);

    const redis = getRedisClient();
    await redis.set(
      `team_invite:${token}`,
      JSON.stringify({ teamId: id, email, role: role || "member", invitedBy: invitedByUserId, tenantId }),
      "EX",
      INVITE_TTL
    );

    const updated = await this.updateById(
      id,
      {
        $push: {
          invites: {
            email,
            role: role || "member",
            invitedBy: invitedByUserId,
            token,
            message,
            expiresAt,
            status: "pending",
          },
        },
      },
      { tenantId }
    );

    // Email via RabbitMQ
    await publishToQueue(RabbitQueues.EMAIL, {
      channel: "email",
      to: email,
      templateName: "teamInvite",
      templateData: {
        teamName: team.name,
        role: role || "member",
        message,
        inviteToken: token,
        expiresAt,
        invitedBy: invitedByUserId,
      },
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.member_invited",
      resourceType: "team",
      resourceId: id,
      actor: { id: invitedByUserId },
      tenantId,
      metadata: { email, role },
    });

    return updated;
  }

  // ── Accept Invite ───────────────────────────────────────────────────────────

  async acceptInvite(token, userId, userEmail) {
    const redis = getRedisClient();
    const raw = await redis.get(`team_invite:${token}`);
    if (!raw) throw notFound("Invite token is invalid or has expired");

    const { teamId, email, role, invitedBy, tenantId } = JSON.parse(raw);

    if (email !== userEmail) throw forbidden("Invite email does not match your account");

    const team = await this.getTeamById(teamId, tenantId);

    // Mark invite as accepted in the team document
    await this.updateById(
      teamId,
      {
        $set: { "invites.$[inv].status": "accepted", "invites.$[inv].acceptedAt": new Date() },
        $push: { members: { userId, role, status: "active", invitedBy, joinedAt: new Date() } },
      },
      { tenantId, arrayFilters: [{ "inv.token": token }] }
    );

    // Revoke from Redis
    await redis.del(`team_invite:${token}`);

    // Kafka
    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.member_joined",
      teamId,
      tenantId,
      userId,
      role,
    });

    // WebSocket — notify existing team members
    emitToUser(invitedBy, SocketEvents.MEMBER_JOINED, {
      teamId,
      teamName: team.name,
      userId,
      role,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.invite_accepted",
      resourceType: "team",
      resourceId: teamId,
      actor: { id: userId },
      tenantId,
    });

    return { teamId, role };
  }

  // ── Remove Member ───────────────────────────────────────────────────────────

  async removeMember(teamId, memberId, tenantId, actorId) {
    const team = await this.getTeamById(teamId, tenantId);

    const actor = team.members.find((m) => m.userId.toString() === actorId && m.status === "active");
    if (!actor || !["owner", "admin"].includes(actor.role)) {
      throw forbidden("Insufficient permissions to remove members");
    }

    const target = team.members.find((m) => m.userId.toString() === memberId);
    if (!target) throw notFound("Member not found in team");
    if (target.role === "owner") throw forbidden("Cannot remove the team owner");

    await this.updateById(
      teamId,
      { $set: { "members.$[m].status": "removed" } },
      { tenantId, arrayFilters: [{ "m.userId": memberId }] }
    );

    emitToUser(memberId, SocketEvents.NOTIFICATION, {
      type: "team.removed",
      teamId,
      teamName: team.name,
    });

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.member_removed",
      teamId,
      memberId,
      tenantId,
      removedBy: actorId,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.member_removed",
      resourceType: "team",
      resourceId: teamId,
      actor: { id: actorId },
      tenantId,
      metadata: { memberId },
    });
  }

  // ── Leave Team ──────────────────────────────────────────────────────────────

  async leaveTeam(teamId, userId, tenantId) {
    const team = await this.getTeamById(teamId, tenantId);
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === "active");
    if (!member) throw notFound("You are not an active member of this team");
    if (member.role === "owner") throw forbidden("Transfer ownership before leaving the team");

    await this.updateById(
      teamId,
      { $set: { "members.$[m].status": "removed" } },
      { tenantId, arrayFilters: [{ "m.userId": userId }] }
    );

    await publishEvent(KafkaTopics.WORKSPACE_EVENTS, tenantId, {
      type: "team.member_left",
      teamId,
      userId,
      tenantId,
    });
  }

  // ── Update Member Role ──────────────────────────────────────────────────────

  async updateMemberRole(teamId, memberId, newRole, tenantId, actorId) {
    const team = await this.getTeamById(teamId, tenantId);

    const actor = team.members.find((m) => m.userId.toString() === actorId && m.status === "active");
    if (!actor || actor.role !== "owner") throw forbidden("Only owner can change member roles");

    await this.updateById(
      teamId,
      { $set: { "members.$[m].role": newRole } },
      { tenantId, arrayFilters: [{ "m.userId": memberId }] }
    );

    emitToUser(memberId, SocketEvents.NOTIFICATION, {
      type: "team.role_changed",
      teamId,
      newRole,
    });

    await publishToQueue(RabbitQueues.AUDIT, {
      action: "team.member_role_changed",
      resourceType: "team",
      resourceId: teamId,
      actor: { id: actorId },
      tenantId,
      metadata: { memberId, newRole },
    });
  }
}

export const teamService = new TeamService();
