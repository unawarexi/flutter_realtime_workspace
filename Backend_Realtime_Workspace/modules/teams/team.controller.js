import Team from '../../models/teamModel.js';
import Project from '../../models/projectModel.js';
import UserInfo from '../../models/userInfoModel.js';
import mongoose from 'mongoose';

export const createTeam = async (req, res) => {
  try {
    console.log('[createTeam] req.user:', req.user);
    console.log('[createTeam] req.body:', req.body);

    const { name, description, industry, size, type, settings, members } = req.body;

    // Get the correct user ID from the auth middleware
    const firebaseUid = req.user.uid; // Firebase UID
    const mongoId = req.user.mongoId; // MongoDB ObjectID

    console.log('[createTeam] Firebase UID:', firebaseUid);
    console.log('[createTeam] MongoDB ID:', mongoId);

    // Use the userRecord from middleware or find the user
    let user = req.user.userRecord;

    if (!user) {
      // Fallback: find user by Firebase UID
      user = await UserInfo.findOne({ userID: firebaseUid });

      // If still not found, try by MongoDB ObjectId
      if (!user && mongoose.Types.ObjectId.isValid(mongoId)) {
        user = await UserInfo.findById(mongoId);
      }
    }

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Create team with owner as first member
    // Use MongoDB ObjectID for database references
    const team = new Team({
      name,
      description,
      industry,
      size,
      type,
      createdBy: mongoId, // Use MongoDB ObjectID for database relations
      settings: settings || {},
      members: [
        {
          userId: mongoId, // Use MongoDB ObjectID for consistency
          role: 'owner',
          permissions: {
            canCreateProjects: true,
            canDeleteProjects: true,
            canManageMembers: true,
            canInviteMembers: true,
            canChangeSettings: true,
            canViewAllProjects: true,
            canExportData: true,
            canManageIntegrations: true
          },
          status: 'active'
        }
      ]
    });

    // Add additional members if provided (skip owner)
    if (Array.isArray(members)) {
      for (const m of members) {
        // Skip if userId is missing or null
        if (!m.userId) {
          console.log('[createTeam] Skipping member with missing userId:', m);
          continue;
        }

        // Convert to string for comparison (handles both ObjectId and string)
        const memberUserId = m.userId.toString();
        const ownerUserId = mongoId.toString();

        // Skip if userId is owner
        if (memberUserId === ownerUserId) {
          console.log('[createTeam] Skipping owner in members array');
          continue;
        }

        // Avoid duplicates
        if (team.members.some((mem) => mem.userId && mem.userId.toString() === memberUserId)) {
          console.log('[createTeam] Skipping duplicate member:', memberUserId);
          continue;
        }

        // Set role/status or use defaults
        team.members.push({
          userId: m.userId,
          role: m.role || 'member',
          permissions: team.getDefaultPermissions(m.role || 'member'),
          status: m.status || 'active',
          joinedAt: new Date()
        });
      }
    }

    await team.save();

    // Add initial activity
    team.addActivity('team_created', mongoId, null, 'Team created');
    await team.save();

    const populatedTeam = await Team.findById(team._id).populate('members.userId', 'fullName email profilePicture').populate('createdBy', 'fullName email');

    res.status(201).json({
      success: true,
      message: 'Team created successfully',
      data: populatedTeam
    });

    console.log('[createTeam] REACHED END, sent 201 response');
  } catch (error) {
    console.log('[createTeam][ERROR]', error);
    res.status(500).json({
      error: 'Failed to create team',
      details: error.message
    });
    console.log('[createTeam] SENT 500 response');
  }
};

export const getUserTeams = async (req, res) => {
  try {
    console.log('[getUserTeams] req.user:', req.user);
    console.log('[getUserTeams] req.query:', req.query);
    const userId = req.user.id;
    const { status = 'active', limit = 20, page = 1 } = req.query;

    const skip = (page - 1) * limit;

    const teams = await Team.find({
      'members.userId': userId,
      'members.status': 'active',
      status
    })
      .populate('members.userId', 'fullName email profilePicture roleTitle')
      .populate('createdBy', 'fullName email')
      .sort({ updatedAt: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    const total = await Team.countDocuments({
      'members.userId': userId,
      'members.status': 'active',
      status
    });

    res.json({
      success: true,
      data: teams,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('[getUserTeams][ERROR]', error);
    res.status(500).json({
      error: 'Failed to fetch teams',
      details: error.message
    });
  }
};

export const getTeam = async (req, res) => {
  try {
    console.log('[getTeam] req.user:', req.user);
    console.log('[getTeam] req.params:', req.params);
    const { identifier } = req.params; // can be ID or slug
    const userId = req.user.id;

    let team;
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      team = await Team.findById(identifier);
    } else {
      team = await Team.findBySlug(identifier);
    }

    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check if user is a member
    const isMember = team.members.some((member) => member.userId.toString() === userId && member.status === 'active');

    if (!isMember && !team.settings.isPublic) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const populatedTeam = await Team.findById(team._id)
      .populate('members.userId', 'fullName email profilePicture roleTitle lastActive')
      .populate('createdBy', 'fullName email')
      .populate('invites.invitedBy', 'fullName email')
      .populate({
        path: 'projects',
        select: 'name description status priority progress createdAt',
        match: { archived: false }
      });

    res.json({
      success: true,
      data: populatedTeam
    });
  } catch (error) {
    console.error('[getTeam][ERROR]', error);
    res.status(500).json({
      error: 'Failed to fetch team',
      details: error.message
    });
  }
};

export const updateTeam = async (req, res) => {
  try {
    console.log('[updateTeam] req.user:', req.user);
    console.log('[updateTeam] req.params:', req.params);
    console.log('[updateTeam] req.body:', req.body);
    const { teamId } = req.params;
    const userId = req.user.id;
    const updates = req.body;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member || !member.permissions.canChangeSettings) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Update allowed fields
    const allowedUpdates = ['name', 'description', 'industry', 'size', 'type', 'avatar', 'settings', 'memberLimit'];

    allowedUpdates.forEach((field) => {
      if (updates[field] !== undefined) {
        team[field] = updates[field];
      }
    });

    await team.save();

    // Add activity
    team.addActivity('team_updated', userId, null, 'Team settings updated');
    await team.save();

    const updatedTeam = await Team.findById(teamId).populate('members.userId', 'fullName email profilePicture');

    res.json({
      success: true,
      message: 'Team updated successfully',
      data: updatedTeam
    });
  } catch (error) {
    console.error('[updateTeam][ERROR]', error);
    res.status(500).json({
      error: 'Failed to update team',
      details: error.message
    });
  }
};

export const deleteTeam = async (req, res) => {
  try {
    console.log('[deleteTeam] req.user:', req.user);
    console.log('[deleteTeam] req.params:', req.params);
    const { teamId } = req.params;
    const userId = req.user.id;
    const { permanent = false } = req.query;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Only owner can delete team
    const member = team.members.find((m) => m.userId.toString() === userId && m.role === 'owner');

    if (!member) {
      return res.status(403).json({ error: 'Only team owner can delete team' });
    }

    if (permanent) {
      // Permanent deletion - also delete all projects
      await Project.deleteMany({ teamId });
      await Team.findByIdAndDelete(teamId);
    } else {
      // Archive team
      team.status = 'archived';
      team.archived = true;
      team.archivedAt = new Date();
      team.archivedBy = userId;
      await team.save();

      // Archive all team projects
      await Project.updateMany(
        { teamId },
        {
          archived: true,
          status: 'archived',
          archivedAt: new Date()
        }
      );
    }

    res.json({
      success: true,
      message: permanent ? 'Team deleted permanently' : 'Team archived successfully'
    });
  } catch (error) {
    console.error('[deleteTeam][ERROR]', error);
    res.status(500).json({
      error: 'Failed to delete team',
      details: error.message
    });
  }
};

// ==================== MEMBER MANAGEMENT ====================

export const inviteMember = async (req, res) => {
  try {
    console.log('[inviteMember] req.user:', req.user);
    console.log('[inviteMember] req.params:', req.params);
    console.log('[inviteMember] req.body:', req.body);
    const { teamId } = req.params;
    const { email, role = 'member', message = '' } = req.body;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member || !member.permissions.canInviteMembers) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Check if user is already a member
    const existingUser = await UserInfo.findOne({ email });
    if (existingUser) {
      const isAlreadyMember = team.members.some((m) => m.userId.toString() === existingUser._id.toString());
      if (isAlreadyMember) {
        return res.status(400).json({ error: 'User is already a team member' });
      }
    }

    await team.inviteMember(email, role, userId, message);

    // TODO: Send invitation email here

    res.json({
      success: true,
      message: 'Invitation sent successfully'
    });
  } catch (error) {
    console.error('[inviteMember][ERROR]', error);
    res.status(500).json({
      error: 'Failed to invite member',
      details: error.message
    });
  }
};

export const acceptInvitation = async (req, res) => {
  try {
    console.log('[acceptInvitation] req.user:', req.user);
    console.log('[acceptInvitation] req.params:', req.params);
    const { token } = req.params;
    const userId = req.user.id;

    const team = await Team.findOne({ 'invites.token': token });
    if (!team) {
      return res.status(404).json({ error: 'Invalid invitation' });
    }

    await team.acceptInvite(token, userId);

    const updatedTeam = await Team.findById(team._id).populate('members.userId', 'fullName email profilePicture');

    res.json({
      success: true,
      message: 'Invitation accepted successfully',
      data: updatedTeam
    });
  } catch (error) {
    console.error('[acceptInvitation][ERROR]', error);
    res.status(500).json({
      error: 'Failed to accept invitation',
      details: error.message
    });
  }
};

export const updateMemberRole = async (req, res) => {
  try {
    console.log('[updateMemberRole] req.user:', req.user);
    console.log('[updateMemberRole] req.params:', req.params);
    console.log('[updateMemberRole] req.body:', req.body);
    const { teamId, memberId } = req.params;
    const { role } = req.body;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const currentMember = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!currentMember || !currentMember.permissions.canManageMembers) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    await team.updateMemberRole(memberId, role, userId);

    res.json({
      success: true,
      message: 'Member role updated successfully'
    });
  } catch (error) {
    console.error('[updateMemberRole][ERROR]', error);
    res.status(500).json({
      error: 'Failed to update member role',
      details: error.message
    });
  }
};

export const removeMember = async (req, res) => {
  try {
    console.log('[removeMember] req.user:', req.user);
    console.log('[removeMember] req.params:', req.params);
    const { teamId, memberId } = req.params;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const currentMember = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!currentMember || !currentMember.permissions.canManageMembers) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    await team.removeMember(memberId, userId);

    res.json({
      success: true,
      message: 'Member removed successfully'
    });
  } catch (error) {
    console.error('[removeMember][ERROR]', error);
    res.status(500).json({
      error: 'Failed to remove member',
      details: error.message
    });
  }
};

export const leaveTeam = async (req, res) => {
  try {
    console.log('[leaveTeam] req.user:', req.user);
    console.log('[leaveTeam] req.params:', req.params);
    const { teamId } = req.params;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member) {
      return res.status(404).json({ error: 'You are not a member of this team' });
    }

    if (member.role === 'owner') {
      return res.status(400).json({
        error: 'Team owner cannot leave. Transfer ownership first.'
      });
    }

    await team.removeMember(userId, userId);

    res.json({
      success: true,
      message: 'Successfully left the team'
    });
  } catch (error) {
    console.error('[leaveTeam][ERROR]', error);
    res.status(500).json({
      error: 'Failed to leave team',
      details: error.message
    });
  }
};

export const transferOwnership = async (req, res) => {
  try {
    console.log('[transferOwnership] req.user:', req.user);
    console.log('[transferOwnership] req.params:', req.params);
    console.log('[transferOwnership] req.body:', req.body);
    const { teamId } = req.params;
    const { newOwnerId } = req.body;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check if current user is owner
    const currentOwner = team.members.find((m) => m.userId.toString() === userId && m.role === 'owner');

    if (!currentOwner) {
      return res.status(403).json({ error: 'Only team owner can transfer ownership' });
    }

    // Check if new owner is a member
    const newOwner = team.members.find((m) => m.userId.toString() === newOwnerId && m.status === 'active');

    if (!newOwner) {
      return res.status(404).json({ error: 'New owner must be an active team member' });
    }

    // Transfer ownership
    currentOwner.role = 'admin';
    currentOwner.permissions = team.getDefaultPermissions('admin');

    newOwner.role = 'owner';
    newOwner.permissions = team.getDefaultPermissions('owner');

    await team.save();

    // Add activity
    team.addActivity('member_role_changed', userId, newOwnerId, 'Team ownership transferred');
    await team.save();

    res.json({
      success: true,
      message: 'Ownership transferred successfully'
    });
  } catch (error) {
    console.error('[transferOwnership][ERROR]', error);
    res.status(500).json({
      error: 'Failed to transfer ownership',
      details: error.message
    });
  }
};

// ==================== PROJECT MANAGEMENT ====================

export const getTeamProjects = async (req, res) => {
  try {
    console.log('[getTeamProjects] req.user:', req.user);
    console.log('[getTeamProjects] req.params:', req.params);
    console.log('[getTeamProjects] req.query:', req.query);
    const { teamId } = req.params;
    const userId = req.user.id;
    const { status, priority, archived = false, limit = 20, page = 1, sortBy = 'updatedAt', sortOrder = 'desc' } = req.query;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check if user is a member
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Build query
    const query = { teamId, archived: archived === 'true' };
    if (status) query.status = status;
    if (priority) query.priority = priority;

    const skip = (page - 1) * limit;
    const sort = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const projects = await Project.find(query).populate('createdBy', 'fullName email profilePicture').populate('members', 'fullName email profilePicture').sort(sort).limit(parseInt(limit)).skip(skip);

    const total = await Project.countDocuments(query);

    res.json({
      success: true,
      data: projects,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('[getTeamProjects][ERROR]', error);
    res.status(500).json({
      error: 'Failed to fetch team projects',
      details: error.message
    });
  }
};

export const assignProject = async (req, res) => {
  try {
    console.log('[assignProject] req.user:', req.user);
    console.log('[assignProject] req.params:', req.params);
    console.log('[assignProject] req.body:', req.body);
    const { teamId, projectId } = req.params;
    const { memberIds } = req.body;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member || !member.permissions.canViewAllProjects) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Validate member IDs
    const validMembers = memberIds.filter((id) => team.members.some((m) => m.userId.toString() === id && m.status === 'active'));

    project.members = [...new Set([...project.members, ...validMembers])];
    await project.save();

    // Add timeline event
    await project.addTimelineEvent('Members Assigned', `${validMembers.length} members assigned to project`, 'collaborators');

    res.json({
      success: true,
      message: 'Project assigned successfully'
    });
  } catch (error) {
    console.error('[assignProject][ERROR]', error);
    res.status(500).json({
      error: 'Failed to assign project',
      details: error.message
    });
  }
};

// ==================== ANALYTICS & REPORTING ====================

export const getTeamAnalytics = async (req, res) => {
  try {
    console.log('[getTeamAnalytics] req.user:', req.user);
    console.log('[getTeamAnalytics] req.params:', req.params);
    console.log('[getTeamAnalytics] req.query:', req.query);
    const { teamId } = req.params;
    const userId = req.user.id;
    const { period = '30d' } = req.query;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();

    switch (period) {
      case '7d':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(startDate.getDate() - 30);
        break;
      case '90d':
        startDate.setDate(startDate.getDate() - 90);
        break;
      case '1y':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default:
        startDate.setDate(startDate.getDate() - 30);
    }

    // Get team statistics
    const [teamStats] = await Team.getTeamStats(teamId);

    // Get project analytics
    const projectAnalytics = await Project.aggregate([
      { $match: { teamId: new mongoose.Types.ObjectId(teamId) } },
      {
        $group: {
          _id: null,
          totalProjects: { $sum: 1 },
          activeProjects: {
            $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] }
          },
          completedProjects: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          onHoldProjects: {
            $sum: { $cond: [{ $eq: ['$status', 'on-hold'] }, 1, 0] }
          },
          averageProgress: { $avg: '$progress' },
          totalAttachments: { $sum: { $size: '$attachments' } }
        }
      }
    ]);

    // Get member activity
    const memberActivity = await Team.aggregate([
      { $match: { _id: new mongoose.Types.ObjectId(teamId) } },
      { $unwind: '$members' },
      {
        $match: {
          'members.status': 'active',
          'members.lastActive': { $gte: startDate }
        }
      },
      {
        $group: {
          _id: null,
          activeMembers: { $sum: 1 },
          totalMembers: { $sum: 1 }
        }
      }
    ]);

    // Get recent activities
    const recentActivities = team.activities.filter((activity) => activity.timestamp >= startDate).slice(0, 10);

    res.json({
      success: true,
      data: {
        team: teamStats,
        projects: projectAnalytics[0] || {},
        members: memberActivity[0] || { activeMembers: 0, totalMembers: 0 },
        recentActivities,
        period: {
          startDate,
          endDate,
          days: Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24))
        }
      }
    });
  } catch (error) {
    console.error('[getTeamAnalytics][ERROR]', error);
    res.status(500).json({
      error: 'Failed to fetch team analytics',
      details: error.message
    });
  }
};

export const getActivityFeed = async (req, res) => {
  try {
    console.log('[getActivityFeed] req.user:', req.user);
    console.log('[getActivityFeed] req.params:', req.params);
    console.log('[getActivityFeed] req.query:', req.query);
    const { teamId } = req.params;
    const userId = req.user.id;
    const { limit = 20, page = 1, type } = req.query;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member) {
      return res.status(403).json({ error: 'Access denied' });
    }

    let activities = team.activities;

    // Filter by type if specified
    if (type) {
      activities = activities.filter((activity) => activity.type === type);
    }

    // Pagination
    const skip = (page - 1) * limit;
    const paginatedActivities = activities.slice(skip, skip + limit);

    // Populate user data for activities
    const populatedActivities = await Team.populate(paginatedActivities, [
      { path: 'actor', select: 'fullName email profilePicture' },
      { path: 'target', select: 'fullName email profilePicture' }
    ]);

    res.json({
      success: true,
      data: populatedActivities,
      pagination: {
        total: activities.length,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(activities.length / limit)
      }
    });
  } catch (error) {
    console.error('[getActivityFeed][ERROR]', error);
    res.status(500).json({
      error: 'Failed to fetch activity feed',
      details: error.message
    });
  }
};

// ==================== SEARCH & DISCOVERY ====================

export const searchTeams = async (req, res) => {
  try {
    console.log('[searchTeams] req.user:', req.user);
    console.log('[searchTeams] req.query:', req.query);
    const { q, limit = 10, includePublic = false } = req.query;
    const userId = req.user.id;

    if (!q || q.trim().length < 2) {
      return res.status(400).json({ error: 'Search query must be at least 2 characters' });
    }

    const searchQuery = {
      $and: [
        {
          $or: [{ name: { $regex: q, $options: 'i' } }, { description: { $regex: q, $options: 'i' } }, { industry: { $regex: q, $options: 'i' } }]
        },
        {
          $or: [
            { 'members.userId': userId }, // User's teams
            ...(includePublic === 'true' ? [{ 'settings.isPublic': true }] : [])
          ]
        },
        { status: 'active' }
      ]
    };

    const teams = await Team.find(searchQuery)
      .populate('members.userId', 'fullName email profilePicture')
      .populate('createdBy', 'fullName email')
      .select('-activities -invites') // Exclude sensitive data
      .limit(parseInt(limit))
      .sort({ updatedAt: -1 });

    res.json({
      success: true,
      data: teams,
      count: teams.length
    });
  } catch (error) {
    console.error('[searchTeams][ERROR]', error);
    res.status(500).json({
      error: 'Failed to search teams',
      details: error.message
    });
  }
};

// ==================== INTEGRATIONS ====================

export const updateIntegrations = async (req, res) => {
  try {
    console.log('[updateIntegrations] req.user:', req.user);
    console.log('[updateIntegrations] req.params:', req.params);
    console.log('[updateIntegrations] req.body:', req.body);
    const { teamId } = req.params;
    const { integrations } = req.body;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member || !member.permissions.canManageIntegrations) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Update integrations
    team.integrations = { ...team.integrations, ...integrations };
    await team.save();

    // Add activity
    team.addActivity('settings_changed', userId, null, 'Team integrations updated');
    await team.save();

    res.json({
      success: true,
      message: 'Integrations updated successfully',
      data: team.integrations
    });
  } catch (error) {
    console.log('[updateIntegrations][ERROR]', error);
    res.status(500).json({
      error: 'Failed to update integrations',
      details: error.message
    });
  }
};

// ==================== BULK OPERATIONS ====================

export const bulkUpdatePermissions = async (req, res) => {
  try {
    console.log('[bulkUpdatePermissions] req.user:', req.user);
    console.log('[bulkUpdatePermissions] req.params:', req.params);
    console.log('[bulkUpdatePermissions] req.body:', req.body);
    const { teamId } = req.params;
    const { updates } = req.body; // Array of { memberId, permissions }
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check permissions
    const currentMember = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!currentMember || !currentMember.permissions.canManageMembers) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Apply updates
    let updatedCount = 0;
    for (const update of updates) {
      const member = team.members.find((m) => m.userId.toString() === update.memberId && m.status === 'active');

      if (member && member.role !== 'owner') {
        member.permissions = { ...member.permissions, ...update.permissions };
        updatedCount++;
      }
    }

    await team.save();

    // Add activity
    team.addActivity('member_role_changed', userId, null, `Bulk updated permissions for ${updatedCount} members`);
    await team.save();

    res.json({
      success: true,
      message: `Updated permissions for ${updatedCount} members`
    });
  } catch (error) {
    console.error('[bulkUpdatePermissions][ERROR]', error);
    res.status(500).json({
      error: 'Failed to update permissions',
      details: error.message
    });
  }
};

// ==================== UTILITY METHODS ====================

export const checkPermissions = async (req, res) => {
  try {
    console.log('[checkPermissions] req.user:', req.user);
    console.log('[checkPermissions] req.params:', req.params);
    const { teamId } = req.params;
    const userId = req.user.id;

    const team = await Team.findById(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    const member = team.members.find((m) => m.userId.toString() === userId && m.status === 'active');

    if (!member) {
      return res.status(403).json({ error: 'Not a team member' });
    }

    res.json({
      success: true,
      data: {
        role: member.role,
        permissions: member.permissions,
        isOwner: member.role === 'owner'
      }
    });
  } catch (error) {
    console.error('[checkPermissions][ERROR]', error);
    res.status(500).json({
      error: 'Failed to check permissions',
      details: error.message
    });
  }
};
