import ScheduleMeet from '../models/scheduleMeet-Model.js';
import mongoose from 'mongoose';
import UserInfo from '../models/userInfoModel.js';
import { uploadToCloudinary } from '../services/cloudinary.js';

// ======================== CREATE OPERATIONS ========================
export const createMeeting = async (req, res) => {
  try {
    // Get authenticated user info (organizer)
    const organizerUID = req.user?.uid;
    if (!organizerUID) {
      return res.status(401).json({ success: false, message: 'Unauthorized: Organizer not found' });
    }

    // Fetch organizer details from UserInfo
    const organizerInfo = await UserInfo.findOne({ userID: organizerUID });
    if (!organizerInfo) {
      return res.status(400).json({ success: false, message: 'Organizer user info not found' });
    }

    // Parse fields if sent as JSON strings (from multipart/form-data)
    let {
      meetingTitle,
      description,
      agenda,
      meetingDate,
      meetingTime,
      duration,
      timezone,
      repeatOption,
      recurrenceEndDate,
      meetingType,
      location,
      participants,
      visibility,
      allowGuestUsers,
      requireApproval,
      reminderSettings,
      companyName,
      department,
      teamProjectName,
      // attachments, // REMOVE: handle attachments below
    } = req.body;

    // If fields are stringified JSON (from multipart), parse them
    if (typeof participants === 'string') participants = JSON.parse(participants);
    if (typeof location === 'string') location = JSON.parse(location);
    if (typeof reminderSettings === 'string') reminderSettings = JSON.parse(reminderSettings);

    // Validate required fields
    if (!meetingTitle || !meetingDate || !meetingTime || !duration || !meetingType) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: meetingTitle, meetingDate, meetingTime, duration, meetingType',
      });
    }

    // Ensure meetingTime.start exists
    if (!meetingTime.start) {
      return res.status(400).json({
        success: false,
        message: 'meetingTime.start is required',
      });
    }

    // Auto-calculate meetingTime.end if not provided
    if (!meetingTime.end) {
      // meetingTime.start is in "HH:mm" format
      const [startHours, startMinutes] = meetingTime.start.split(':').map(Number);
      const startTotalMinutes = startHours * 60 + startMinutes;
      const endTotalMinutes = startTotalMinutes + duration;
      const endHours = Math.floor(endTotalMinutes / 60) % 24;
      const endMinutes = endTotalMinutes % 60;
      meetingTime.end = `${String(endHours).padStart(2, '0')}:${String(endMinutes).padStart(2, '0')}`;
    }

    // Validate duration
    if (typeof duration !== 'number' || duration < 5 || duration > 480) {
      return res.status(400).json({
        success: false,
        message: 'Duration must be a number between 5 and 480 minutes',
      });
    }

    // Fetch participant details from UserInfo
    let participantObjs = [];
    if (participants && participants.length > 0) {
      // Accept array of { userID } or { email }
      const userIDs = participants.map((p) => p.userID).filter(Boolean);
      const emails = participants.map((p) => p.email).filter(Boolean);
      const users = await UserInfo.find({
        $or: [...(userIDs.length ? [{ userID: { $in: userIDs } }] : []), ...(emails.length ? [{ email: { $in: emails } }] : [])],
      });

      participantObjs = users.map((user) => ({
        userID: user.userID,
        name: user.fullName || user.displayName,
        email: user.email,
        profilePicture: user.profilePicture,
        roleTitle: user.roleTitle,
        department: user.department,
        permissionsLevel: user.permissionsLevel,
        status: 'invited',
      }));
    }

    // Compose organizer object
    const organizer = {
      userID: organizerInfo.userID,
      name: organizerInfo.fullName || organizerInfo.displayName,
      email: organizerInfo.email,
      profilePicture: organizerInfo.profilePicture,
      roleTitle: organizerInfo.roleTitle,
      department: organizerInfo.department,
    };

    // Compose createdBy object
    const createdBy = {
      userID: organizerInfo.userID,
      name: organizerInfo.fullName || organizerInfo.displayName,
      ipAddress: req.ip,
    };

    // Handle attachments: accept array of strings (file URLs) or array of objects
    let attachments = [];
    if (req.files && req.files.length > 0) {
      const uploadPromises = req.files.map(async (file) => {
        const uploadResult = await uploadToCloudinary(file.buffer, file.originalname, '/meetings/attachments');
        return {
          fileName: file.originalname,
          fileUrl: uploadResult.secure_url || uploadResult.url,
          fileSize: uploadResult.bytes,
          mimeType: file.mimetype,
          uploadedBy: {
            userID: organizerInfo.userID,
            name: organizerInfo.fullName || organizerInfo.displayName,
          },
          uploadedAt: new Date(),
          isPublic: true,
          public_id: uploadResult.public_id,
          resource_type: uploadResult.resource_type,
          format: uploadResult.format,
          width: uploadResult.width,
          height: uploadResult.height,
          duration: uploadResult.duration,
        };
      });
      attachments = await Promise.all(uploadPromises);
    } else if (req.body.attachments && Array.isArray(req.body.attachments)) {
      // If frontend sends array of strings (URLs), convert to expected object format
      attachments = req.body.attachments.map((fileUrl) => ({
        fileName: typeof fileUrl === 'string' ? fileUrl.split('/').pop() : '',
        fileUrl: fileUrl,
        isPublic: true,
        uploadedAt: new Date(),
        uploadedBy: {
          userID: organizerInfo.userID,
          name: organizerInfo.fullName || organizerInfo.displayName,
        },
      }));
    }

    // Create meeting object
    const meetingData = {
      meetingTitle,
      description,
      agenda,
      organizer,
      meetingDate: new Date(meetingDate),
      meetingTime,
      duration,
      timezone: timezone || 'UTC',
      repeatOption: repeatOption || 'None',
      meetingType,
      location: location || {},
      participants: participantObjs,
      visibility: visibility || 'team-only',
      allowGuestUsers: allowGuestUsers || false,
      requireApproval: requireApproval || false,
      reminderSettings: reminderSettings || {
        enabled: true,
        reminderTime: '15 minutes before',
        notificationMethods: ['push', 'email'],
      },
      companyName,
      department,
      teamProjectName,
      createdBy,
      attachments, // <-- Save attachments array
    };

    // Add recurrence end date if recurring
    if (repeatOption && repeatOption !== 'None' && recurrenceEndDate) {
      meetingData.recurrenceEndDate = new Date(recurrenceEndDate);
    }

    const newMeeting = new ScheduleMeet(meetingData);

    // Check for conflicts if participants are provided
    if (participantObjs.length > 0) {
      await newMeeting.checkConflicts();
    }

    await newMeeting.save();

    // Handle recurring meetings
    if (repeatOption && repeatOption !== 'None') {
      const recurringMeetings = await createRecurringMeetings(newMeeting);
      newMeeting.recurringMeetings = recurringMeetings.map((meeting) => meeting._id);
      await newMeeting.save();
    }

    res.status(201).json({
      success: true,
      message: 'Meeting created successfully',
      data: newMeeting,
    });
  } catch (error) {
    console.error('Error creating meeting:', error); // Add stack trace for debugging
    res.status(500).json({
      success: false,
      message: 'Error creating meeting',
      error: error.message,
      stack: error.stack, // Add stack for debugging
    });
  }
};

/**
 * Create recurring meetings based on parent meeting
 * @param {Object} parentMeeting - The parent meeting object
 */
export const createRecurringMeetings = async (parentMeeting) => {
  const recurringMeetings = [];
  const endDate = parentMeeting.recurrenceEndDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year default
  let currentDate = new Date(parentMeeting.meetingDate);

  const repeatMap = {
    Daily: 1,
    Weekly: 7,
    'Bi-weekly': 14,
    Monthly: 30,
  };

  const intervalDays = repeatMap[parentMeeting.repeatOption];
  if (!intervalDays) return recurringMeetings;

  while (currentDate < endDate) {
    currentDate = new Date(currentDate.getTime() + intervalDays * 24 * 60 * 60 * 1000);

    if (currentDate > endDate) break;

    const recurringMeeting = new ScheduleMeet({
      ...parentMeeting.toObject(),
      _id: new mongoose.Types.ObjectId(),
      meetingDate: currentDate,
      recurringMeetings: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await recurringMeeting.save();
    recurringMeetings.push(recurringMeeting);
  }

  return recurringMeetings;
};

// ======================== READ OPERATIONS ========================

/**
 * Get all meetings with pagination and filtering
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getAllMeetings = async (req, res) => {
  try {
    const { page = 1, limit = 10, status, meetingType, companyName, department, startDate, endDate, search, sortBy = 'meetingDate', sortOrder = 'asc' } = req.query;

    const filter = { isDeleted: { $ne: true } };

    // Apply filters
    if (status) filter.status = status;
    if (meetingType) filter.meetingType = meetingType;
    if (companyName) filter.companyName = companyName;
    if (department) filter.department = department;

    // Date range filter
    if (startDate || endDate) {
      filter.meetingDate = {};
      if (startDate) filter.meetingDate.$gte = new Date(startDate);
      if (endDate) filter.meetingDate.$lte = new Date(endDate);
    }

    // Search functionality
    if (search) {
      filter.$or = [{ meetingTitle: { $regex: search, $options: 'i' } }, { description: { $regex: search, $options: 'i' } }, { 'organizer.name': { $regex: search, $options: 'i' } }];
    }

    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [meetings, totalCount] = await Promise.all([ScheduleMeet.find(filter).sort(sortOptions).skip(skip).limit(parseInt(limit)).populate('recurringMeetings', 'meetingTitle meetingDate status'), ScheduleMeet.countDocuments(filter)]);

    const totalPages = Math.ceil(totalCount / parseInt(limit));

    res.status(200).json({
      success: true,
      data: meetings,
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalCount,
        hasNextPage: parseInt(page) < totalPages,
        hasPreviousPage: parseInt(page) > 1,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching meetings',
      error: error.message,
    });
  }
};

/**
 * Get meeting by ID
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getMeetingById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    }).populate('recurringMeetings', 'meetingTitle meetingDate status');

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching meeting',
      error: error.message,
    });
  }
};

/**
 * Get user's meetings
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getUserMeetings = async (req, res) => {
  try {
    const { userID } = req.params;
    const { status = ['scheduled', 'ongoing'], startDate, endDate, limit = 50 } = req.query;

    const options = {
      status: Array.isArray(status) ? status : [status],
      startDate: startDate ? new Date(startDate) : new Date(),
      limit: parseInt(limit),
    };

    if (endDate) {
      options.endDate = new Date(endDate);
    }

    const meetings = await ScheduleMeet.findUserMeetings(userID, options);

    res.status(200).json({
      success: true,
      data: meetings,
      count: meetings.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user meetings',
      error: error.message,
    });
  }
};

/**
 * Get today's meetings for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getTodaysMeetings = async (req, res) => {
  try {
    const { userID } = req.params;

    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));

    const meetings = await ScheduleMeet.find({
      $or: [{ 'organizer.userID': userID }, { 'participants.userID': userID }],
      meetingDate: {
        $gte: startOfDay,
        $lte: endOfDay,
      },
      status: { $in: ['scheduled', 'ongoing'] },
      isDeleted: { $ne: true },
    }).sort({ 'meetingTime.start': 1 });

    res.status(200).json({
      success: true,
      data: meetings,
      count: meetings.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching today's meetings",
      error: error.message,
    });
  }
};

/**
 * Get upcoming meetings for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getUpcomingMeetings = async (req, res) => {
  try {
    const { userID } = req.params;
    const { limit = 10 } = req.query;

    const meetings = await ScheduleMeet.find({
      $or: [{ 'organizer.userID': userID }, { 'participants.userID': userID }],
      meetingDate: { $gt: new Date() },
      status: 'scheduled',
      isDeleted: { $ne: true },
    })
      .sort({ meetingDate: 1 })
      .limit(parseInt(limit));

    res.status(200).json({
      success: true,
      data: meetings,
      count: meetings.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching upcoming meetings',
      error: error.message,
    });
  }
};

// ======================== UPDATE OPERATIONS ========================

/**
 * Update meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateMeeting = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    // Add last modified info
    updateData.lastModifiedBy = {
      userID: req.body.modifiedBy?.userID,
      name: req.body.modifiedBy?.name,
      modifiedAt: new Date(),
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, updateData, {
      new: true,
      runValidators: true,
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    // Recheck conflicts if participants or time changed
    if (updateData.participants || updateData.meetingDate || updateData.meetingTime || updateData.duration) {
      await meeting.checkConflicts();
    }

    res.status(200).json({
      success: true,
      message: 'Meeting updated successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating meeting',
      error: error.message,
    });
  }
};

/**
 * Update meeting status
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateMeetingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, reason, userInfo } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const validStatuses = ['scheduled', 'ongoing', 'ended', 'cancelled', 'postponed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const updateData = {
      status,
      lastModifiedBy: {
        userID: userInfo?.userID,
        name: userInfo?.name,
        modifiedAt: new Date(),
      },
    };

    // Handle specific status updates
    if (status === 'cancelled' && reason) {
      updateData.cancellationReason = reason;
    }

    if (status === 'ongoing') {
      updateData.actualStartTime = new Date();
    }

    if (status === 'ended') {
      updateData.actualEndTime = new Date();
      // Calculate actual meeting duration
      if (updateData.actualStartTime) {
        const duration = (updateData.actualEndTime - updateData.actualStartTime) / (1000 * 60);
        updateData['analytics.meetingDuration'] = Math.round(duration);
      }
    }

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, updateData, {
      new: true,
      runValidators: true,
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: `Meeting status updated to ${status}`,
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating meeting status',
      error: error.message,
    });
  }
};

/**
 * Postpone meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const postponeMeeting = async (req, res) => {
  try {
    const { id } = req.params;
    const { newDate, newTime, reason, userInfo } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    if (!newDate || !newTime) {
      return res.status(400).json({
        success: false,
        message: 'New date and time are required for postponing',
      });
    }

    const updateData = {
      status: 'postponed',
      postponedTo: {
        date: new Date(newDate),
        time: newTime,
      },
      cancellationReason: reason,
      lastModifiedBy: {
        userID: userInfo?.userID,
        name: userInfo?.name,
        modifiedAt: new Date(),
      },
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, updateData, {
      new: true,
      runValidators: true,
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting postponed successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error postponing meeting',
      error: error.message,
    });
  }
};

// ======================== DELETE OPERATIONS ========================

/**
 * Soft delete meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const deleteMeeting = async (req, res) => {
  try {
    const { id } = req.params;
    const { userInfo } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      { _id: id, isDeleted: { $ne: true } },
      {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: {
          userID: userInfo?.userID,
          name: userInfo?.name,
        },
      },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting meeting',
      error: error.message,
    });
  }
};

/**
 * Permanently delete meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const permanentlyDeleteMeeting = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findByIdAndDelete(id);

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting permanently deleted',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error permanently deleting meeting',
      error: error.message,
    });
  }
};

/**
 * Restore deleted meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const restoreMeeting = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      { _id: id, isDeleted: true },
      {
        isDeleted: false,
        $unset: { deletedAt: 1, deletedBy: 1 },
      },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Deleted meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting restored successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error restoring meeting',
      error: error.message,
    });
  }
};

// ======================== PARTICIPANT MANAGEMENT ========================

/**
 * Add participant to meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const addParticipant = async (req, res) => {
  try {
    const { id } = req.params;
    const { userInfo, status = 'invited' } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    await meeting.addParticipant(userInfo, status);

    res.status(200).json({
      success: true,
      message: 'Participant added successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding participant',
      error: error.message,
    });
  }
};

/**
 * Remove participant from meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const removeParticipant = async (req, res) => {
  try {
    const { id, userID } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $pull: { participants: { userID: userID } } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Participant removed successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error removing participant',
      error: error.message,
    });
  }
};

/**
 * Update participant status
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateParticipantStatus = async (req, res) => {
  try {
    const { id, userID } = req.params;
    const { status } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const validStatuses = ['invited', 'accepted', 'declined', 'tentative', 'no-response'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid participant status',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    await meeting.updateParticipantStatus(userID, status);

    res.status(200).json({
      success: true,
      message: 'Participant status updated successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating participant status',
      error: error.message,
    });
  }
};

/**
 * Record participant join time
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const recordParticipantJoin = async (req, res) => {
  try {
    const { id, userID } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      {
        _id: id,
        'participants.userID': userID,
        isDeleted: { $ne: true },
      },
      {
        $set: {
          'participants.$.joinedAt': new Date(),
          'participants.$.status': 'accepted',
        },
      },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting or participant not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Participant join time recorded',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error recording participant join',
      error: error.message,
    });
  }
};

/**
 * Record participant leave time
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const recordParticipantLeave = async (req, res) => {
  try {
    const { id, userID } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      {
        _id: id,
        'participants.userID': userID,
        isDeleted: { $ne: true },
      },
      {
        $set: {
          'participants.$.leftAt': new Date(),
        },
      },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting or participant not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Participant leave time recorded',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error recording participant leave',
      error: error.message,
    });
  }
};

// ======================== ATTACHMENT MANAGEMENT ========================

/**
 * Add attachment to meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const addAttachment = async (req, res) => {
  try {
    const { id } = req.params;
    const { fileName, fileUrl, fileSize, mimeType, uploadedBy, isPublic = true } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const attachment = {
      fileName,
      fileUrl,
      fileSize,
      mimeType,
      uploadedBy,
      isPublic,
      uploadedAt: new Date(),
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $push: { attachments: attachment } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Attachment added successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding attachment',
      error: error.message,
    });
  }
};

/**
 * Remove attachment from meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const removeAttachment = async (req, res) => {
  try {
    const { id, attachmentId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $pull: { attachments: { _id: attachmentId } } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Attachment removed successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error removing attachment',
      error: error.message,
    });
  }
};

// ======================== CONFLICT DETECTION ========================

/**
 * Check meeting conflicts
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const checkConflicts = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    await meeting.checkConflicts();

    res.status(200).json({
      success: true,
      message: 'Conflicts checked successfully',
      data: {
        hasConflicts: meeting.conflictingMeetings.length > 0,
        conflicts: meeting.conflictingMeetings,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking conflicts',
      error: error.message,
    });
  }
};

/**
 * Get user's conflicting meetings for a specific time slot
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getUserConflicts = async (req, res) => {
  try {
    const { userID } = req.params;
    const { meetingDate, duration, excludeMeetingId } = req.query;

    if (!meetingDate || !duration) {
      return res.status(400).json({
        success: false,
        message: 'Meeting date and duration are required',
      });
    }

    const startTime = new Date(meetingDate);
    const endTime = new Date(startTime.getTime() + parseInt(duration) * 60000);

    const query = {
      $or: [{ 'organizer.userID': userID }, { 'participants.userID': userID }],
      status: 'scheduled',
      isDeleted: { $ne: true },
      meetingDate: {
        $gte: new Date(startTime.getTime() - parseInt(duration) * 60000),
        $lte: endTime,
      },
    };

    if (excludeMeetingId && mongoose.Types.ObjectId.isValid(excludeMeetingId)) {
      query._id = { $ne: excludeMeetingId };
    }

    const conflicts = await ScheduleMeet.find(query);

    res.status(200).json({
      success: true,
      data: conflicts,
      hasConflicts: conflicts.length > 0,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking user conflicts',
      error: error.message,
    });
  }
};

// ======================== ANALYTICS & REPORTING ========================

/**
 * Get meeting analytics
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getMeetingAnalytics = async (req, res) => {
  try {
    const { companyName } = req.params;
    const { startDate, endDate, department } = req.query;

    const options = {};
    if (startDate) options.startDate = new Date(startDate);
    if (endDate) options.endDate = new Date(endDate);
    if (department) options.department = department;

    const analytics = await ScheduleMeet.getAnalytics(companyName, options);

    res.status(200).json({
      success: true,
      data: analytics[0] || {
        totalMeetings: 0,
        scheduledMeetings: 0,
        completedMeetings: 0,
        cancelledMeetings: 0,
        avgAttendees: 0,
        totalAttendees: 0,
        avgDuration: 0,
        totalDuration: 0,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching analytics',
      error: error.message,
    });
  }
};

/**
 * Get user meeting statistics
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getUserMeetingStats = async (req, res) => {
  try {
    const { userID } = req.params;
    const { startDate, endDate } = req.query;

    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);

    const matchQuery = {
      $or: [{ 'organizer.userID': userID }, { 'participants.userID': userID }],
      isDeleted: { $ne: true },
    };

    if (Object.keys(dateFilter).length > 0) {
      matchQuery.meetingDate = dateFilter;
    }

    const stats = await ScheduleMeet.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: null,
          totalMeetings: { $sum: 1 },
          organizedMeetings: {
            $sum: { $cond: [{ $eq: ['$organizer.userID', userID] }, 1, 0] },
          },
          attendedMeetings: {
            $sum: {
              $cond: [
                {
                  $and: [{ $ne: ['$organizer.userID', userID] }, { $in: [userID, '$participants.userID'] }],
                },
                1,
                0,
              ],
            },
          },
          scheduledMeetings: {
            $sum: { $cond: [{ $eq: ['$status', 'scheduled'] }, 1, 0] },
          },
          completedMeetings: {
            $sum: { $cond: [{ $eq: ['$status', 'ended'] }, 1, 0] },
          },
          cancelledMeetings: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] },
          },
          totalDuration: { $sum: '$duration' },
          avgDuration: { $avg: '$duration' },
        },
      },
    ]);

    res.status(200).json({
      success: true,
      data: stats[0] || {
        totalMeetings: 0,
        organizedMeetings: 0,
        attendedMeetings: 0,
        scheduledMeetings: 0,
        completedMeetings: 0,
        cancelledMeetings: 0,
        totalDuration: 0,
        avgDuration: 0,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user statistics',
      error: error.message,
    });
  }
};

// ======================== CALENDAR INTEGRATION ========================

/**
 * Get calendar view of meetings
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getCalendarView = async (req, res) => {
  try {
    const { userID } = req.params;
    const { month, year } = req.query;

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const meetings = await ScheduleMeet.find({
      $or: [{ 'organizer.userID': userID }, { 'participants.userID': userID }],
      meetingDate: {
        $gte: startDate,
        $lte: endDate,
      },
      isDeleted: { $ne: true },
    }).sort({ meetingDate: 1, 'meetingTime.start': 1 });

    // Group meetings by date
    const calendarData = {};
    meetings.forEach((meeting) => {
      const dateKey = meeting.meetingDate.toISOString().split('T')[0];
      if (!calendarData[dateKey]) {
        calendarData[dateKey] = [];
      }
      calendarData[dateKey].push(meeting);
    });

    res.status(200).json({
      success: true,
      data: calendarData,
      totalMeetings: meetings.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching calendar view',
      error: error.message,
    });
  }
};

// ======================== SEARCH & FILTERING ========================

/**
 * Search meetings with advanced filters
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const searchMeetings = async (req, res) => {
  try {
    const { q: searchQuery, userID, status, meetingType, startDate, endDate, department, companyName, organizer, page = 1, limit = 20 } = req.query;

    let filter = { isDeleted: { $ne: true } };

    // User-specific meetings
    if (userID) {
      filter.$or = [{ 'organizer.userID': userID }, { 'participants.userID': userID }];
    }

    // Text search
    if (searchQuery) {
      filter.$and = filter.$and || [];
      filter.$and.push({
        $or: [
          { meetingTitle: { $regex: searchQuery, $options: 'i' } },
          { description: { $regex: searchQuery, $options: 'i' } },
          { agenda: { $regex: searchQuery, $options: 'i' } },
          { 'organizer.name': { $regex: searchQuery, $options: 'i' } },
          { 'participants.name': { $regex: searchQuery, $options: 'i' } },
        ],
      });
    }

    // Status filter
    if (status) {
      const statusArray = Array.isArray(status) ? status : [status];
      filter.status = { $in: statusArray };
    }

    // Meeting type filter
    if (meetingType) {
      filter.meetingType = meetingType;
    }

    // Date range filter
    if (startDate || endDate) {
      filter.meetingDate = {};
      if (startDate) filter.meetingDate.$gte = new Date(startDate);
      if (endDate) filter.meetingDate.$lte = new Date(endDate);
    }

    // Department filter
    if (department) {
      filter.department = department;
    }

    // Company filter
    if (companyName) {
      filter.companyName = companyName;
    }

    // Organizer filter
    if (organizer) {
      filter['organizer.userID'] = organizer;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [meetings, totalCount] = await Promise.all([ScheduleMeet.find(filter).sort({ meetingDate: -1 }).skip(skip).limit(parseInt(limit)), ScheduleMeet.countDocuments(filter)]);

    res.status(200).json({
      success: true,
      data: meetings,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalCount / parseInt(limit)),
        totalCount,
        hasNextPage: parseInt(page) < Math.ceil(totalCount / parseInt(limit)),
        hasPreviousPage: parseInt(page) > 1,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching meetings',
      error: error.message,
    });
  }
};

// ======================== BULK OPERATIONS ========================

/**
 * Bulk update meetings
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const bulkUpdateMeetings = async (req, res) => {
  try {
    const { meetingIds, updateData, userInfo } = req.body;

    if (!Array.isArray(meetingIds) || meetingIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Meeting IDs array is required',
      });
    }

    // Validate ObjectIds
    const invalidIds = meetingIds.filter((id) => !mongoose.Types.ObjectId.isValid(id));
    if (invalidIds.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid meeting IDs: ${invalidIds.join(', ')}`,
      });
    }

    // Add modification metadata
    updateData.lastModifiedBy = {
      userID: userInfo?.userID,
      name: userInfo?.name,
      modifiedAt: new Date(),
    };

    const result = await ScheduleMeet.updateMany(
      {
        _id: { $in: meetingIds },
        isDeleted: { $ne: true },
      },
      updateData
    );

    res.status(200).json({
      success: true,
      message: `${result.modifiedCount} meetings updated successfully`,
      data: {
        matchedCount: result.matchedCount,
        modifiedCount: result.modifiedCount,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error bulk updating meetings',
      error: error.message,
    });
  }
};

/**
 * Bulk delete meetings
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const bulkDeleteMeetings = async (req, res) => {
  try {
    const { meetingIds, userInfo } = req.body;

    if (!Array.isArray(meetingIds) || meetingIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Meeting IDs array is required',
      });
    }

    // Validate ObjectIds
    const invalidIds = meetingIds.filter((id) => !mongoose.Types.ObjectId.isValid(id));
    if (invalidIds.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid meeting IDs: ${invalidIds.join(', ')}`,
      });
    }

    const result = await ScheduleMeet.updateMany(
      {
        _id: { $in: meetingIds },
        isDeleted: { $ne: true },
      },
      {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: {
          userID: userInfo?.userID,
          name: userInfo?.name,
        },
      }
    );

    res.status(200).json({
      success: true,
      message: `${result.modifiedCount} meetings deleted successfully`,
      data: {
        matchedCount: result.matchedCount,
        modifiedCount: result.modifiedCount,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error bulk deleting meetings',
      error: error.message,
    });
  }
};

// ======================== NOTIFICATION MANAGEMENT ========================

/**
 * Update reminder settings for a meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateReminderSettings = async (req, res) => {
  try {
    const { id } = req.params;
    const { reminderSettings } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { reminderSettings }, { new: true, runValidators: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Reminder settings updated successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating reminder settings',
      error: error.message,
    });
  }
};

/**
 * Send meeting invitations
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const sendInvitations = async (req, res) => {
  try {
    const { id } = req.params;
    const { participantIds, customMessage } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    // Update invitation status for specified participants or all
    const filter = participantIds ? { userID: { $in: participantIds } } : {};

    await ScheduleMeet.updateOne(
      { _id: id },
      {
        $set: {
          'participants.$[elem].invitationSent': true,
          'participants.$[elem].invitationSentAt': new Date(),
          'participants.$[elem].customMessage': customMessage,
        },
      },
      {
        arrayFilters: [{ 'elem.userID': filter.userID || { $exists: true } }],
      }
    );

    res.status(200).json({
      success: true,
      message: 'Invitations sent successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error sending invitations',
      error: error.message,
    });
  }
};

/**
 * Get meeting invitations for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getUserInvitations = async (req, res) => {
  try {
    const { userID } = req.params;
    const { status = 'invited', page = 1, limit = 20 } = req.query;

    const filter = {
      'participants.userID': userID,
      'participants.status': status,
      isDeleted: { $ne: true },
      status: 'scheduled',
    };

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [invitations, totalCount] = await Promise.all([ScheduleMeet.find(filter).sort({ meetingDate: 1 }).skip(skip).limit(parseInt(limit)), ScheduleMeet.countDocuments(filter)]);

    res.status(200).json({
      success: true,
      data: invitations,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalCount / parseInt(limit)),
        totalCount,
        hasNextPage: parseInt(page) < Math.ceil(totalCount / parseInt(limit)),
        hasPreviousPage: parseInt(page) > 1,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user invitations',
      error: error.message,
    });
  }
};

// ======================== MEETING TEMPLATES ========================

/**
 * Create meeting template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const createMeetingTemplate = async (req, res) => {
  try {
    const { templateName, description, defaultDuration, defaultMeetingType, defaultAgenda, defaultParticipants, defaultReminderSettings, createdBy, companyName, department, isPublic = false } = req.body;

    if (!templateName || !createdBy) {
      return res.status(400).json({
        success: false,
        message: 'Template name and creator information are required',
      });
    }

    const templateData = {
      templateName,
      description,
      defaultDuration: defaultDuration || 30,
      defaultMeetingType: defaultMeetingType || 'virtual',
      defaultAgenda,
      defaultParticipants: defaultParticipants || [],
      defaultReminderSettings: defaultReminderSettings || {
        enabled: true,
        reminderTime: '15 minutes before',
        notificationMethods: ['push', 'email'],
      },
      createdBy,
      companyName,
      department,
      isPublic,
      isTemplate: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const template = new ScheduleMeet(templateData);
    await template.save();

    res.status(201).json({
      success: true,
      message: 'Meeting template created successfully',
      data: template,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating meeting template',
      error: error.message,
    });
  }
};

/**
 * Get meeting templates
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const getMeetingTemplates = async (req, res) => {
  try {
    const { userID, companyName, department, isPublic } = req.query;

    let filter = {
      isTemplate: true,
      isDeleted: { $ne: true },
    };

    // Add filters based on query parameters
    if (isPublic === 'true') {
      filter.isPublic = true;
    } else if (userID) {
      filter.$or = [{ 'createdBy.userID': userID }, { isPublic: true }];
    }

    if (companyName) filter.companyName = companyName;
    if (department) filter.department = department;

    const templates = await ScheduleMeet.find(filter).sort({ createdAt: -1 }).select('-recurringMeetings -conflictingMeetings -participants -attachments');

    res.status(200).json({
      success: true,
      data: templates,
      count: templates.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching meeting templates',
      error: error.message,
    });
  }
};

/**
 * Create meeting from template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const createFromTemplate = async (req, res) => {
  try {
    const { templateId } = req.params;
    const { meetingTitle, meetingDate, meetingTime, organizer, participants, customizations = {} } = req.body;

    if (!mongoose.Types.ObjectId.isValid(templateId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid template ID format',
      });
    }

    const template = await ScheduleMeet.findOne({
      _id: templateId,
      isTemplate: true,
      isDeleted: { $ne: true },
    });

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Meeting template not found',
      });
    }

    // Create meeting data from template
    const meetingData = {
      meetingTitle: meetingTitle || template.templateName,
      description: customizations.description || template.description,
      agenda: customizations.agenda || template.defaultAgenda,
      organizer,
      meetingDate: new Date(meetingDate),
      meetingTime,
      duration: customizations.duration || template.defaultDuration,
      timezone: customizations.timezone || 'UTC',
      meetingType: customizations.meetingType || template.defaultMeetingType,
      participants: participants || template.defaultParticipants,
      reminderSettings: customizations.reminderSettings || template.defaultReminderSettings,
      companyName: template.companyName,
      department: template.department,
      createdBy: organizer,
      createdFromTemplate: templateId,
    };

    const newMeeting = new ScheduleMeet(meetingData);
    await newMeeting.save();

    res.status(201).json({
      success: true,
      message: 'Meeting created from template successfully',
      data: newMeeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating meeting from template',
      error: error.message,
    });
  }
};

// ======================== MEETING NOTES ========================

/**
 * Add meeting notes
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const addMeetingNotes = async (req, res) => {
  try {
    const { id } = req.params;
    const { notes, addedBy } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    if (!notes || !addedBy) {
      return res.status(400).json({
        success: false,
        message: 'Notes content and author information are required',
      });
    }

    const noteData = {
      content: notes,
      addedBy,
      addedAt: new Date(),
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $push: { meetingNotes: noteData } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting notes added successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding meeting notes',
      error: error.message,
    });
  }
};

/**
 * Update meeting notes
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateMeetingNotes = async (req, res) => {
  try {
    const { id, noteId } = req.params;
    const { notes, updatedBy } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      {
        _id: id,
        'meetingNotes._id': noteId,
        isDeleted: { $ne: true },
      },
      {
        $set: {
          'meetingNotes.$.content': notes,
          'meetingNotes.$.updatedBy': updatedBy,
          'meetingNotes.$.updatedAt': new Date(),
        },
      },
      { new: true }
    );

    if (!meeting) {
 return res.status(404).json({
        success: false,
        message: 'Meeting or note not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Meeting notes updated successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating meeting notes',
      error: error.message,
    });
  }
};

// ======================== TIME ZONE MANAGEMENT ========================

/**
 * Convert meeting time to different timezone
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const convertMeetingTimezone = async (req, res) => {
  try {
    const { id } = req.params;
    const { targetTimezone } = req.query;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    // Simple timezone conversion (you may want to use a library like moment-timezone)
    const meetingDateTime = new Date(`${meeting.meetingDate.toDateString()} ${meeting.meetingTime.start}`);

    const convertedMeeting = {
      ...meeting.toObject(),
      convertedTime: {
        originalTimezone: meeting.timezone,
        targetTimezone: targetTimezone,
        originalDateTime: meetingDateTime,
        convertedDateTime: meetingDateTime, // This would need proper timezone conversion
      },
    };

    res.status(200).json({
      success: true,
      data: convertedMeeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error converting meeting timezone',
      error: error.message,
    });
  }
};

// ======================== MEETING RECORDINGS ========================

/**
 * Add recording to meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const addRecording = async (req, res) => {
  try {
    const { id } = req.params;
    const { recordingUrl, recordingTitle, duration, uploadedBy } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const recordingData = {
      url: recordingUrl,
      title: recordingTitle || 'Meeting Recording',
      duration: duration || 0,
      uploadedBy,
      uploadedAt: new Date(),
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $push: { recordings: recordingData } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Recording added successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding recording',
      error: error.message,
    });
  }
};

// ======================== AVAILABILITY CHECKING ========================

/**
 * Check participant availability
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const checkParticipantAvailability = async (req, res) => {
  try {
    const { participantIds, meetingDate, duration } = req.query;

    if (!participantIds || !meetingDate || !duration) {
      return res.status(400).json({
        success: false,
        message: 'Participant IDs, meeting date, and duration are required',
      });
    }

    const participantArray = Array.isArray(participantIds) ? participantIds : [participantIds];
    const startTime = new Date(meetingDate);
    const endTime = new Date(startTime.getTime() + parseInt(duration) * 60000);

    const availabilityData = {};

    for (const participantId of participantArray) {
      const conflicts = await ScheduleMeet.find({
        $or: [{ 'organizer.userID': participantId }, { 'participants.userID': participantId }],
        status: 'scheduled',
        isDeleted: { $ne: true },
        meetingDate: {
          $gte: new Date(startTime.getTime() - parseInt(duration) * 60000),
          $lte: endTime,
        },
      });

      availabilityData[participantId] = {
        available: conflicts.length === 0,
        conflicts: conflicts.map((meeting) => ({
          id: meeting._id,
          title: meeting.meetingTitle,
          date: meeting.meetingDate,
          time: meeting.meetingTime,
          duration: meeting.duration,
        })),
      };
    }

    res.status(200).json({
      success: true,
      data: availabilityData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking participant availability',
      error: error.message,
    });
  }
};

// ======================== MEETING FOLLOW-UPS ========================

/**
 * Add follow-up action to meeting
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const addFollowUpAction = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, assignedTo, dueDate, priority = 'medium', createdBy } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({success: false, message: 'Invalid meeting ID format',});
    }

    const followUpData = {
      action,
      assignedTo,
      dueDate: dueDate ? new Date(dueDate) : null,
      priority,
      status: 'pending',
      createdBy,
      createdAt: new Date(),
    };

    const meeting = await ScheduleMeet.findOneAndUpdate({ _id: id, isDeleted: { $ne: true } }, { $push: { followUpActions: followUpData } }, { new: true });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Follow-up action added successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding follow-up action',
      error: error.message,
    });
  }
};

/**
 * Update follow-up action status
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateFollowUpStatus = async (req, res) => {
  try {
    const { id, actionId } = req.params;
    const { status, updatedBy, completedAt } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const validStatuses = ['pending', 'in-progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid follow-up action status',
      });
    }

    const updateData = {
      'followUpActions.$.status': status,
      'followUpActions.$.updatedBy': updatedBy,
      'followUpActions.$.updatedAt': new Date(),
    };

    if (status === 'completed' && completedAt) {
      updateData['followUpActions.$.completedAt'] = new Date(completedAt);
    }

    const meeting = await ScheduleMeet.findOneAndUpdate(
      {
        _id: id,
        'followUpActions._id': actionId,
        isDeleted: { $ne: true },
      },
      { $set: updateData },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({success: false, message: 'Meeting or follow-up action not found',});
    }

    res.status(200).json({
      success: true,
      message: 'Follow-up action status updated successfully',
      data: meeting,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating follow-up action status',
      error: error.message,
    });
  }
};

// ======================== EXPORT & INTEGRATION ========================

/**
 * Export meeting data
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const exportMeetingData = async (req, res) => {
  try {
    const { format = 'json', startDate, endDate, companyName, userID } = req.query;

    let filter = { isDeleted: { $ne: true } };

    if (startDate || endDate) {
      filter.meetingDate = {};
      if (startDate) filter.meetingDate.$gte = new Date(startDate);
      if (endDate) filter.meetingDate.$lte = new Date(endDate);
    }

    if (companyName) filter.companyName = companyName;

    if (userID) {
      filter.$or = [{ 'organizer.userID': userID }, { 'participants.userID': userID }];
    }

    const meetings = await ScheduleMeet.find(filter).sort({ meetingDate: -1 }).lean();

    if (format === 'csv') {
      // Convert to CSV format (you may want to use a CSV library)
      const csvData = meetings.map((meeting) => ({
        title: meeting.meetingTitle,
        date: meeting.meetingDate,
        time: meeting.meetingTime?.start,
        duration: meeting.duration,
        organizer: meeting.organizer?.name,
        status: meeting.status,
        type: meeting.meetingType,
        participants: meeting.participants?.length || 0,
      }));

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=meetings.csv');
      return res.status(200).json(csvData); // You'd convert this to actual CSV
    }

    res.status(200).json({
      success: true,
      format,
      exportedAt: new Date(),
      count: meetings.length,
      data: meetings,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error exporting meeting data',
      error: error.message,
    });
  }
};

// ======================== RECURRING MEETINGS MANAGEMENT ========================

/**
 * Update recurring meeting series
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const updateRecurringSeries = async (req, res) => {
  try {
    const { id } = req.params;
    const { updateType, updateData } = req.body; // updateType: 'this', 'future', 'all'

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    let updateResult;

    switch (updateType) {
      case 'this':
        // Update only this instance
        updateResult = await ScheduleMeet.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
        break;

      case 'future':
        // Update this and all future instances
        updateResult = await ScheduleMeet.updateMany(
          {
            $or: [
              { _id: id },
              {
                _id: { $in: meeting.recurringMeetings },
                meetingDate: { $gte: meeting.meetingDate },
              },
            ],
          },
          updateData
        );
        break;

      case 'all':
        // Update all instances in the series
        updateResult = await ScheduleMeet.updateMany(
          {
            $or: [{ _id: id }, { _id: { $in: meeting.recurringMeetings } }],
          },
          updateData
        );
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid update type. Use "this", "future", or "all"',
        });
    }

    res.status(200).json({
      success: true,
      message: `Recurring meeting series updated (${updateType})`,
      data: updateResult,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating recurring meeting series',
      error: error.message,
    });
  }
};

/**
 * Cancel recurring meeting series
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
export const cancelRecurringSeries = async (req, res) => {
  try {
    const { id } = req.params;
    const { cancelType, reason, userInfo } = req.body; // cancelType: 'this', 'future', 'all'

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid meeting ID format',
      });
    }

    const meeting = await ScheduleMeet.findOne({
      _id: id,
      isDeleted: { $ne: true },
    });

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found',
      });
    }

    const updateData = {
      status: 'cancelled',
      cancellationReason: reason,
      lastModifiedBy: {
        userID: userInfo?.userID,
        name: userInfo?.name,
        modifiedAt: new Date(),
      },
    };

    let cancelResult;

    switch (cancelType) {
      case 'this':
        cancelResult = await ScheduleMeet.findByIdAndUpdate(id, updateData, { new: true });
        break;

      case 'future':
        cancelResult = await ScheduleMeet.updateMany(
          {
            $or: [
              { _id: id },
              {
                _id: { $in: meeting.recurringMeetings },
                meetingDate: { $gte: meeting.meetingDate },
              },
            ],
          },
          updateData
        );
        break;

      case 'all':
        cancelResult = await ScheduleMeet.updateMany(
          {
            $or: [{ _id: id }, { _id: { $in: meeting.recurringMeetings } }],
          },
          updateData
        );
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid cancel type. Use "this", "future", or "all"',
        });
    }

    // ✅ Send success response
    return res.status(200).json({
      success: true,
      message: 'Meeting(s) cancelled successfully',
      data: cancelResult,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Server error during cancellation',
      error: error.message,
    });
  }
};
