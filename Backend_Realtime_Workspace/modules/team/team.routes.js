import express from 'express';
import {createTeam, getUserTeams, searchTeams, getTeam, updateTeam, deleteTeam, inviteMember,
  acceptInvitation, updateMemberRole, removeMember, leaveTeam, transferOwnership, bulkUpdatePermissions,
  getTeamProjects, assignProject, getTeamAnalytics, getActivityFeed, updateIntegrations, checkPermissions
} from './team.controller.js';
import { firebaseAuthMiddleware } from '../middlewares/firebaseAuthMiddleware.js';
import { validateTeamInput, validateInviteInput, validateMemberRoleUpdate } from '../middlewares/teamValidationMiddleware.js';

const router = express.Router();

// Compose both middlewares into one array
const teamMiddlewares = [
  firebaseAuthMiddleware,
  (req, res, next) => {
    console.log(`[teamRoutes] ${req.method} ${req.originalUrl}`);
    next();
  }
];

// Apply both middlewares to all routes
router.use(teamMiddlewares);

// Create a new team
router.post('/', validateTeamInput, createTeam);

// Get all teams for the authenticated user
router.get('/', getUserTeams);

// Search teams
router.get('/search', searchTeams);

// Get team by ID or slug
router.get('/:identifier', getTeam);

// Update team
router.put('/:teamId', validateTeamInput, updateTeam);

// Delete/Archive team
router.delete('/:teamId', deleteTeam);

// Invite member to team
router.post('/:teamId/invite', validateInviteInput, inviteMember);

// Accept team invitation
router.post('/invitations/:token/accept', acceptInvitation);

// Update member role
router.put('/:teamId/members/:memberId/role', validateMemberRoleUpdate, updateMemberRole);

// Remove member from team
router.delete('/:teamId/members/:memberId', removeMember);

// Leave team
router.post('/:teamId/leave', leaveTeam);

// Transfer team ownership
router.post('/:teamId/transfer-ownership', transferOwnership);

// Bulk update member permissions
router.put('/:teamId/members/bulk-permissions', bulkUpdatePermissions);

// Get team projects
router.get('/:teamId/projects', getTeamProjects);

// Assign project to team members
router.post('/:teamId/projects/:projectId/assign', assignProject);

// Get team analytics
router.get('/:teamId/analytics', getTeamAnalytics);

// Get team activity feed
router.get('/:teamId/activity', getActivityFeed);

// Update team integrations
router.put('/:teamId/integrations', updateIntegrations);

// Check user permissions for team
router.get('/:teamId/permissions', checkPermissions);

export default router;
