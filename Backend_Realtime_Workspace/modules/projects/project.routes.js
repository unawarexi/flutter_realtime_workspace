import express from 'express';
import {createProject, getProjects, getProjectById, updateProject, deleteProject, uploadAttachment, deleteAttachment,
  getProjectAttachments, toggleProjectStar, toggleProjectArchive, updateProjectProgress, updateProjectCollaborators,
  addTimelineEvent, getProjectTimeline, getProjectStats, duplicateProject, getNewProjectKey,getNewTeamId,
} from './project.controller.js';
import { upload, multerErrorHandler } from '../services/cloudinary.js';
import { firebaseAuthMiddleware } from '../middlewares/firebaseAuthMiddleware.js';

const router = express.Router();

// Apply firebaseAuthMiddleware to all routes
router.use(firebaseAuthMiddleware);

// Project CRUD Operations
router.post('/', upload.array('attachments', 10), multerErrorHandler, createProject);
router.get('/', getProjects);
router.get('/stats', getProjectStats);
router.get('/:id', getProjectById);
router.put('/:id', updateProject);
router.delete('/:id', deleteProject);

// Project Actions
router.patch('/:id/star', toggleProjectStar);
router.patch('/:id/archive', toggleProjectArchive);
router.patch('/:id/progress', updateProjectProgress);
router.post('/:id/duplicate', duplicateProject);

// Collaborators Management
router.patch('/:id/collaborators', updateProjectCollaborators);

// Attachments Management
router.post('/:id/attachments', upload.single('attachment'), multerErrorHandler, uploadAttachment);
router.get('/:id/attachments', getProjectAttachments);
router.delete('/:id/attachments/:attachmentId', deleteAttachment);

// Timeline Management
router.post('/:id/timeline', addTimelineEvent);
router.get('/:id/timeline', getProjectTimeline);

// Add endpoints for generating keys
router.get('/generate/project-key', getNewProjectKey);
router.get('/generate/team-id', getNewTeamId);

export default router;
