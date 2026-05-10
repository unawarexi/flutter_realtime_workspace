import Project from '../../models/projectModel.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.js';
import mongoose from 'mongoose';
import { generateProjectKey, generateTeamId } from '../helpers/project_id_generator.js';

/**
 * Create a new project
 */
export const createProject = async (req, res) => {
  try {
    // Support both JSON and multipart/form-data
    let {
      name,
      description,
      template,
      status,
      priority,
      color,
      teamId,
      collaborators,
      members,
      tags,
      startDate,
      endDate,
      customFields,
      key // allow custom key
    } = req.body;

    // Get the correct user ID from the auth middleware
    const firebaseUid = req.user.uid; // Firebase UID
    const mongoId = req.user.mongoId; // MongoDB ObjectID

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

    // Parse fields if sent as JSON strings (from multipart/form-data)
    if (typeof collaborators === 'string') collaborators = JSON.parse(collaborators);
    if (typeof members === 'string') members = JSON.parse(members);
    if (typeof tags === 'string') tags = JSON.parse(tags);
    if (typeof customFields === 'string') customFields = JSON.parse(customFields);

    // Validate required fields
    if (!name /*|| !teamId*/) {
      return res.status(400).json({
        status: 'error',
        message: 'Project name is required'
      });
    }

    // Use provided key or generate one
    let projectKey = key;
    if (!projectKey) {
      projectKey = generateProjectKey();
    }

    // Create project
    const project = new Project({
      name,
      key: projectKey,
      description,
      template,
      status: status || 'active',
      priority: priority || 'medium',
      color: color || '#1E40AF',
      teamId,
      createdBy: mongoId, // Assuming user is attached to req via auth middleware
      collaborators: collaborators || [],
      members: members || [],
      tags: tags || [],
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      customFields: customFields || {},
      timeline: [
        {
          title: 'Project Created',
          description: 'Project was created',
          date: new Date(),
          type: 'created'
        }
      ]
    });

    // Handle multiple file uploads
    if (req.files && req.files.length > 0) {
      const uploadPromises = req.files.map(async (file) => {
        try {
          // FIX: Use the correct custom folder path as specified
          const uploadResult = await uploadToCloudinary(file.buffer, file.originalname);

          // Log the upload result for debugging
          console.log('Upload result:', JSON.stringify(uploadResult, null, 2));

          // FIX: Handle both secure_url and url fields from Cloudinary
          const fileUrl = uploadResult.secure_url || uploadResult.url;

          if (!fileUrl) {
            throw new Error(`Upload failed: No URL returned for file ${file.originalname}. Upload result: ${JSON.stringify(uploadResult)}`);
          }

          // Ensure all required fields are present and properly structured
          const attachment = {
            url: fileUrl, // Use the correct URL field
            public_id: uploadResult.public_id,
            resource_type: uploadResult.resource_type,
            format: uploadResult.format,
            bytes: uploadResult.bytes,
            filename: uploadResult.filename || file.originalname,
            original_filename: uploadResult.original_filename || file.originalname,
            type: uploadResult.type || file.mimetype,
            width: uploadResult.width || null,
            height: uploadResult.height || null,
            duration: uploadResult.duration || null,
            uploadedAt: new Date(),
            uploadedBy: mongoId
          };

          return attachment;
        } catch (uploadError) {
          console.error(`Failed to upload file ${file.originalname}:`, uploadError);
          throw uploadError;
        }
      });

      try {
        const attachments = await Promise.all(uploadPromises);

        // Validate all attachments have URLs before adding to project
        const validAttachments = attachments.filter((attachment) => attachment.url);

        if (validAttachments.length !== attachments.length) {
          throw new Error('Some attachments failed to upload properly');
        }

        project.attachments.push(...validAttachments);

        // Add timeline events for each attachment
        validAttachments.forEach((attachment) => {
          project.timeline.push({
            title: 'Attachment Added',
            description: `File "${attachment.filename}" was uploaded`,
            date: new Date(),
            type: 'attachment'
          });
        });
      } catch (uploadError) {
        return res.status(500).json({
          status: 'error',
          message: 'Failed to upload one or more attachments',
          error: uploadError.message
        });
      }
    }

    await project.save();

    // Populate related fields
    await project.populate([
      { path: 'createdBy', select: 'name email avatar' },
      { path: 'collaborators', select: 'name email avatar' },
      { path: 'members', select: 'name email avatar' },
      { path: 'teamId', select: 'name description' }
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Project created successfully',
      data: project
    });
  } catch (error) {
    console.error('Create project error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create project',
      error: error.message
    });
  }
};

/**
 * Get all projects with filtering, sorting, and pagination
 */
export const getProjects = async (req, res) => {
  try {
    const { page = 1, limit = 10, status, priority, teamId, starred, recent, archived, search, sortBy = 'updatedAt', sortOrder = 'desc', tags } = req.query;

    // Build filter object
    const filter = {};

    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (teamId) filter.teamId = teamId;
    if (starred !== undefined) filter.starred = starred === 'true';
    if (recent !== undefined) filter.recent = recent === 'true';
    if (archived !== undefined) filter.archived = archived === 'true';
    if (tags) filter.tags = { $in: tags.split(',') };

    // Search functionality
    if (search) {
      filter.$or = [{ name: { $regex: search, $options: 'i' } }, { description: { $regex: search, $options: 'i' } }, { key: { $regex: search, $options: 'i' } }];
    }

    // Calculate pagination
    const skip = (page - 1) * limit;
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query
    const projects = await Project.find(filter)
      .populate([
        { path: 'createdBy', select: 'name email avatar' },
        { path: 'collaborators', select: 'name email avatar' },
        { path: 'members', select: 'name email avatar' },
        { path: 'teamId', select: 'name description' }
      ])
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Project.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);

    res.status(200).json({
      status: 'success',
      data: projects,
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalItems: total,
        itemsPerPage: parseInt(limit),
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
      }
    });
  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch projects',
      error: error.message
    });
  }
};

/**
 * Get a single project by ID
 */
export const getProjectById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id).populate([
      { path: 'createdBy', select: 'name email avatar' },
      { path: 'collaborators', select: 'name email avatar' },
      { path: 'members', select: 'name email avatar' },
      { path: 'teamId', select: 'name description' }
    ]);

    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Update last viewed
    project.lastViewed = new Date();
    await project.save();

    res.status(200).json({
      status: 'success',
      data: project
    });
  } catch (error) {
    console.error('Get project by ID error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch project',
      error: error.message
    });
  }
};

/**
 * Update a project
 */
export const updateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    // Find the project
    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Track what changed for timeline
    const changes = [];
    const fieldsToTrack = ['name', 'description', 'status', 'priority', 'startDate', 'endDate'];

    fieldsToTrack.forEach((field) => {
      if (updateData[field] && updateData[field] !== project[field]) {
        changes.push(`${field} changed from "${project[field]}" to "${updateData[field]}"`);
      }
    });

    // Update the project
    const updatedProject = await Project.findByIdAndUpdate(
      id,
      {
        ...updateData,
        $push:
          changes.length > 0
            ? {
                timeline: {
                  title: 'Project Updated',
                  description: changes.join(', '),
                  date: new Date(),
                  type: 'updated'
                }
              }
            : undefined
      },
      { new: true, runValidators: true }
    ).populate([
      { path: 'createdBy', select: 'name email avatar' },
      { path: 'collaborators', select: 'name email avatar' },
      { path: 'members', select: 'name email avatar' },
      { path: 'teamId', select: 'name description' }
    ]);

    res.status(200).json({
      status: 'success',
      message: 'Project updated successfully',
      data: updatedProject
    });
  } catch (error) {
    console.error('Update project error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update project',
      error: error.message
    });
  }
};

/**
 * Delete a project
 */
export const deleteProject = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Delete all attachments from Cloudinary
    if (project.attachments && project.attachments.length > 0) {
      for (const attachment of project.attachments) {
        try {
          if (typeof attachment === 'object' && attachment.public_id) {
            await deleteFromCloudinary(attachment.public_id, attachment.resource_type);
          }
        } catch (error) {
          console.error('Error deleting attachment:', error);
        }
      }
    }

    await Project.findByIdAndDelete(id);

    res.status(200).json({
      status: 'success',
      message: 'Project deleted successfully'
    });
  } catch (error) {
    console.error('Delete project error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete project',
      error: error.message
    });
  }
};

/**
 * Upload attachment to project
 */
export const uploadAttachment = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        status: 'error',
        message: 'No file uploaded'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Upload to Cloudinary
    const uploadResult = await uploadToCloudinary(req.file.path, `/projects/${project.key}/attachments`, req.file.originalname);

    // Create attachment object
    const attachment = {
      url: uploadResult.url,
      public_id: uploadResult.public_id,
      resource_type: uploadResult.resource_type,
      format: uploadResult.format,
      bytes: uploadResult.bytes,
      filename: uploadResult.filename,
      original_filename: uploadResult.original_filename,
      type: uploadResult.type,
      width: uploadResult.width,
      height: uploadResult.height,
      duration: uploadResult.duration,
      uploadedAt: new Date(),
      uploadedBy: req.user.id
    };

    // Add to attachments array (incrementally)
    project.attachments.push(attachment);

    // Add timeline event
    project.timeline.push({
      title: 'Attachment Added',
      description: `File "${attachment.filename}" was uploaded`,
      date: new Date(),
      type: 'attachment'
    });

    await project.save();

    res.status(200).json({
      status: 'success',
      message: 'File uploaded successfully',
      data: {
        attachment,
        attachmentCount: project.attachments.length
      }
    });
  } catch (error) {
    console.error('Upload attachment error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to upload attachment',
      error: error.message
    });
  }
};

/**
 * Delete a specific attachment from project
 */
export const deleteAttachment = async (req, res) => {
  try {
    const { id, attachmentId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Find attachment
    const attachmentIndex = project.attachments.findIndex((att) => att._id.toString() === attachmentId);

    if (attachmentIndex === -1) {
      return res.status(404).json({
        status: 'error',
        message: 'Attachment not found'
      });
    }

    const attachment = project.attachments[attachmentIndex];

    // Delete from Cloudinary
    try {
      await deleteFromCloudinary(attachment.public_id, attachment.resource_type);
    } catch (error) {
      console.error('Error deleting from Cloudinary:', error);
    }

    // Remove from array
    project.attachments.splice(attachmentIndex, 1);

    // Add timeline event
    project.timeline.push({
      title: 'Attachment Removed',
      description: `File "${attachment.filename}" was deleted`,
      date: new Date(),
      type: 'attachment'
    });

    await project.save();

    res.status(200).json({
      status: 'success',
      message: 'Attachment deleted successfully',
      data: {
        attachmentCount: project.attachments.length
      }
    });
  } catch (error) {
    console.error('Delete attachment error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete attachment',
      error: error.message
    });
  }
};

/**
 * Get project attachments
 */
export const getProjectAttachments = async (req, res) => {
  try {
    const { id } = req.params;
    const { type, page = 1, limit = 10 } = req.query;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id).select('attachments name key');
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    let attachments = project.attachments;

    // Filter by type if specified
    if (type) {
      attachments = attachments.filter((att) => att.type === type);
    }

    // Pagination
    const skip = (page - 1) * limit;
    const paginatedAttachments = attachments.slice(skip, skip + parseInt(limit));
    const total = attachments.length;
    const totalPages = Math.ceil(total / limit);

    res.status(200).json({
      status: 'success',
      data: {
        attachments: paginatedAttachments,
        project: {
          id: project._id,
          name: project.name,
          key: project.key
        }
      },
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalItems: total,
        itemsPerPage: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Get attachments error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch attachments',
      error: error.message
    });
  }
};

/**
 * Toggle project star status
 */
export const toggleProjectStar = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Toggle starred status
    project.starred = !project.starred;

    // Add timeline event
    project.timeline.push({
      title: project.starred ? 'Project Starred' : 'Project Unstarred',
      description: `Project was ${project.starred ? 'added to' : 'removed from'} starred projects`,
      date: new Date(),
      type: 'starred'
    });

    await project.save();

    res.status(200).json({
      status: 'success',
      message: `Project ${project.starred ? 'starred' : 'unstarred'} successfully`,
      data: {
        starred: project.starred
      }
    });
  } catch (error) {
    console.error('Toggle star error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to toggle star status',
      error: error.message
    });
  }
};

/**
 * Archive/Unarchive project
 */
export const toggleProjectArchive = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Toggle archived status
    project.archived = !project.archived;
    project.status = project.archived ? 'archived' : 'active';

    // Add timeline event
    project.timeline.push({
      title: project.archived ? 'Project Archived' : 'Project Restored',
      description: `Project was ${project.archived ? 'archived' : 'restored from archive'}`,
      date: new Date(),
      type: 'archived'
    });

    await project.save();

    res.status(200).json({
      status: 'success',
      message: `Project ${project.archived ? 'archived' : 'restored'} successfully`,
      data: {
        archived: project.archived,
        status: project.status
      }
    });
  } catch (error) {
    console.error('Toggle archive error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to toggle archive status',
      error: error.message
    });
  }
};

/**
 * Update project progress
 */
export const updateProjectProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const { progress } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    if (progress < 0 || progress > 1) {
      return res.status(400).json({
        status: 'error',
        message: 'Progress must be between 0 and 1'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    const oldProgress = project.progress;
    project.progress = progress;

    // Update status based on progress
    if (progress === 1 && project.status !== 'completed') {
      project.status = 'completed';
      project.completed = true;
    } else if (progress < 1 && project.status === 'completed') {
      project.status = 'active';
      project.completed = false;
    }

    // Add timeline event
    project.timeline.push({
      title: 'Progress Updated',
      description: `Progress updated from ${Math.round(oldProgress * 100)}% to ${Math.round(progress * 100)}%`,
      date: new Date(),
      type: 'progress'
    });

    await project.save();

    res.status(200).json({
      status: 'success',
      message: 'Project progress updated successfully',
      data: {
        progress: project.progress,
        status: project.status,
        completed: project.completed
      }
    });
  } catch (error) {
    console.error('Update progress error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update project progress',
      error: error.message
    });
  }
};

/**
 * Add/Remove project collaborators
 */
export const updateProjectCollaborators = async (req, res) => {
  try {
    const { id } = req.params;
    const { collaboratorIds, action = 'add' } = req.body; // action: "add" or "remove"

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    if (!Array.isArray(collaboratorIds) || collaboratorIds.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Collaborator IDs must be provided as an array'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    let message = '';
    let timelineDescription = '';

    if (action === 'add') {
      // Add collaborators (avoid duplicates)
      const newCollaborators = collaboratorIds.filter((id) => !project.collaborators.includes(id));
      project.collaborators.push(...newCollaborators);
      message = `${newCollaborators.length} collaborator(s) added successfully`;
      timelineDescription = `${newCollaborators.length} new collaborator(s) added to project`;
    } else if (action === 'remove') {
      // Remove collaborators
      project.collaborators = project.collaborators.filter((id) => !collaboratorIds.includes(id.toString()));
      message = `${collaboratorIds.length} collaborator(s) removed successfully`;
      timelineDescription = `${collaboratorIds.length} collaborator(s) removed from project`;
    } else {
      return res.status(400).json({
        status: 'error',
        message: "Invalid action. Use 'add' or 'remove'"
      });
    }

    // Add timeline event
    project.timeline.push({
      title: 'Collaborators Updated',
      description: timelineDescription,
      date: new Date(),
      type: 'collaborators'
    });

    await project.save();

    // Populate collaborators for response
    await project.populate('collaborators', 'name email avatar');

    res.status(200).json({
      status: 'success',
      message,
      data: {
        collaborators: project.collaborators,
        collaboratorCount: project.collaborators.length
      }
    });
  } catch (error) {
    console.error('Update collaborators error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update collaborators',
      error: error.message
    });
  }
};

/**
 * Add timeline event to project
 */
export const addTimelineEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, type } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    if (!title) {
      return res.status(400).json({
        status: 'error',
        message: 'Timeline event title is required'
      });
    }

    const project = await Project.findById(id);
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Add timeline event
    const timelineEvent = {
      title,
      description: description || '',
      date: new Date(),
      type: type || 'custom'
    };

    project.timeline.push(timelineEvent);
    await project.save();

    res.status(200).json({
      status: 'success',
      message: 'Timeline event added successfully',
      data: {
        timelineEvent: project.timeline[project.timeline.length - 1],
        timelineCount: project.timeline.length
      }
    });
  } catch (error) {
    console.error('Add timeline event error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to add timeline event',
      error: error.message
    });
  }
};

/**
 * Get project timeline
 */
export const getProjectTimeline = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, type } = req.query;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const project = await Project.findById(id).select('timeline name key');
    if (!project) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    let timeline = [...project.timeline].reverse(); // Most recent first

    // Filter by type if specified
    if (type) {
      timeline = timeline.filter((event) => event.type === type);
    }

    // Pagination
    const skip = (page - 1) * limit;
    const paginatedTimeline = timeline.slice(skip, skip + parseInt(limit));
    const total = timeline.length;
    const totalPages = Math.ceil(total / limit);

    res.status(200).json({
      status: 'success',
      data: {
        timeline: paginatedTimeline,
        project: {
          id: project._id,
          name: project.name,
          key: project.key
        }
      },
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalItems: total,
        itemsPerPage: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Get timeline error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch project timeline',
      error: error.message
    });
  }
};

/**
 * Get project statistics
 */
export const getProjectStats = async (req, res) => {
  try {
    const { teamId } = req.query;
    const filter = teamId ? { teamId } : {};

    const stats = await Project.aggregate([
      { $match: filter },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          active: { $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] } },
          completed: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          archived: { $sum: { $cond: ['$archived', 1, 0] } },
          starred: { $sum: { $cond: ['$starred', 1, 0] } },
          highPriority: {
            $sum: { $cond: [{ $eq: ['$priority', 'high'] }, 1, 0] }
          },
          averageProgress: { $avg: '$progress' },
          totalAttachments: { $sum: { $size: '$attachments' } }
        }
      }
    ]);

    const result = stats[0] || {
      total: 0,
      active: 0,
      completed: 0,
      archived: 0,
      starred: 0,
      highPriority: 0,
      averageProgress: 0,
      totalAttachments: 0
    };

    // Get recent projects
    const recentProjects = await Project.find(filter).sort({ lastViewed: -1 }).limit(5).select('name key lastViewed progress status').populate('createdBy', 'name email');

    res.status(200).json({
      status: 'success',
      data: {
        stats: result,
        recentProjects
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch project statistics',
      error: error.message
    });
  }
};

/**
 * Duplicate a project
 */
export const duplicateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, includeAttachments = false, key } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid project ID'
      });
    }

    const originalProject = await Project.findById(id);
    if (!originalProject) {
      return res.status(404).json({
        status: 'error',
        message: 'Project not found'
      });
    }

    // Use provided key or generate new project key
    let projectKey = key;
    if (!projectKey) {
      projectKey = generateProjectKey();
    }

    // Create duplicate project data
    const duplicateData = {
      name: name || `${originalProject.name} (Copy)`,
      key: projectKey,
      description: originalProject.description,
      template: originalProject.template,
      status: 'active',
      priority: originalProject.priority,
      color: originalProject.color,
      teamId: originalProject.teamId,
      createdBy: req.user.id,
      collaborators: originalProject.collaborators,
      members: originalProject.members,
      tags: originalProject.tags,
      customFields: originalProject.customFields,
      attachments: includeAttachments ? originalProject.attachments : [],
      timeline: [
        {
          title: 'Project Created',
          description: `Project duplicated from ${originalProject.name} (${originalProject.key})`,
          date: new Date(),
          type: 'created'
        }
      ]
    };

    const duplicatedProject = new Project(duplicateData);
    await duplicatedProject.save();

    // Populate related fields
    await duplicatedProject.populate([
      { path: 'createdBy', select: 'name email avatar' },
      { path: 'collaborators', select: 'name email avatar' },
      { path: 'members', select: 'name email avatar' },
      { path: 'teamId', select: 'name description' }
    ]);

    res.status(201).json({
      status: 'success',
      message: 'Project duplicated successfully',
      data: duplicatedProject
    });
  } catch (error) {
    console.error('Duplicate project error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to duplicate project',
      error: error.message
    });
  }
};

/**
 * Endpoint: Generate a new project key
 */
export const getNewProjectKey = (req, res) => {
  try {
    const key = generateProjectKey();
    res.status(200).json({
      status: 'success',
      projectKey: key
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to generate project key',
      error: error.message
    });
  }
};

/**
 * Endpoint: Generate a new team id
 */
export const getNewTeamId = (req, res) => {
  try {
    const teamId = generateTeamId();
    res.status(200).json({
      status: 'success',
      teamId
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to generate team id',
      error: error.message
    });
  }
};
