// mailContent.js - Comprehensive email content generator for TeamSpot workspace app
// This file contains all email templates and content for different scenarios

class EmailContentGenerator {
  constructor() {
    this.baseUrl = process.env.BASE_URL || 'https://teamspot.com';
    this.supportEmail = 'support@teamspot.com';
    this.unsubscribeBaseUrl = `${this.baseUrl}/unsubscribe`;
  }

  // Helper function to generate unsubscribe link
  generateUnsubscribeLink(userId, emailType) {
    return `${this.unsubscribeBaseUrl}?user=${userId}&type=${emailType}`;
  }

  // =====================================
  // AUTHENTICATION EMAILS
  // =====================================

  // Welcome email for new users
  welcomeEmail(userData) {
    return {
      EMAIL_TITLE: "Welcome to TeamSpot - Let's Get Started! 🚀",
      GREETING: `Welcome aboard, ${userData.fullName}! 🎉`,
      MAIN_CONTENT: `
                We're thrilled to have you join the TeamSpot family! Your workspace has been created and you're just moments away from experiencing seamless team collaboration like never before.
                
                <br><br>Your account is now active and ready to use. We've prepared everything you need to hit the ground running with your team.
            `,
      CONTENT_SECTIONS: [
        {
          title: '🚀 Quick Start Guide',
          content: `
                        <p>Here's how to make the most of your first day on TeamSpot:</p>
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Complete your profile:</strong> Add a photo and bio to help your team recognize you</li>
                            <li><strong>Join your first workspace:</strong> Use the invite link or code shared by your team</li>
                            <li><strong>Download our mobile app:</strong> Stay connected on the go</li>
                            <li><strong>Set your availability:</strong> Let your team know when you're online</li>
                        </ul>
                    `
        },
        {
          title: "🎯 What's Next?",
          content: `
                        <p style="color: #475569;">
                            Take a few minutes to explore your dashboard and discover features like real-time messaging, 
                            video conferencing, file sharing, and project management tools. Everything you need to 
                            collaborate effectively is right at your fingertips.
                        </p>
                    `
        }
      ],
      FEATURE_CARDS: [
        {
          icon: '💬',
          title: 'Instant Messaging',
          description: 'Chat with your team in real-time'
        },
        {
          icon: '🎥',
          title: 'Video Meetings',
          description: 'Face-to-face collaboration anywhere'
        },
        {
          icon: '📁',
          title: 'File Sharing',
          description: 'Share and collaborate on documents'
        },
        {
          icon: '📊',
          title: 'Project Management',
          description: 'Track progress and manage tasks'
        }
      ],
      BUTTONS: [
        {
          text: 'Complete Setup',
          url: `${this.baseUrl}/onboarding`,
          primary: true
        },
        {
          text: 'Download Mobile App',
          url: `${this.baseUrl}/mobile`,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
                <div style="background: #F0F9FF; border: 1px solid #BAE6FD; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <h4 style="color: #0369A1; margin-bottom: 8px;">💡 Pro Tip</h4>
                    <p style="color: #0369A1; margin: 0; font-size: 14px;">
                        Join our weekly "TeamSpot Tips" sessions every Tuesday at 2 PM EST to learn advanced features and best practices!
                    </p>
                </div>
            `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, 'welcome')
    };
  }

  // Email verification
  emailVerification(userData) {
    return {
      EMAIL_TITLE: 'Verify Your TeamSpot Account 📧',
      GREETING: `Hi ${userData.fullName}!`,
      MAIN_CONTENT: `
                Thanks for signing up with TeamSpot! To complete your registration and secure your account, 
                please verify your email address by clicking the button below.
                
                <br><br>This verification link will expire in 24 hours for security reasons.
            `,
      BUTTONS: [
        {
          text: 'Verify Email Address',
          url: userData.verificationUrl,
          primary: true
        }
      ],
      ADDITIONAL_CONTENT: `
                <div style="background: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <p style="color: #92400E; margin: 0; font-size: 14px;">
                        <strong>Having trouble?</strong> Copy and paste this link into your browser: 
                        <br><code style="background: #FDE68A; padding: 2px 4px; border-radius: 4px;">${userData.verificationUrl}</code>
                    </p>
                </div>
            `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, 'verification')
    };
  }

  // 2FA code email (for login or sensitive actions)
  twoFactorCodeEmail(userData) {
    return {
      EMAIL_TITLE: 'Verify Your TeamSpot Account',
      GREETING: `Hi ${userData.fullName || userData.userName}!`,
      MAIN_CONTENT: `
        <p style="margin-bottom: 24px;">
          Use the following verification code to complete your sign-in or sensitive action on TeamSpot.
        </p>
        <div style="text-align:center;margin:32px 0;">
          <span style="display:inline-block;font-size:32px;font-weight:700;letter-spacing:8px;background:#F1F5F9;padding:18px 36px;border-radius:12px;border:2px dashed #1e40af;color:#1e40af;">
            ${userData.verificationCode}
          </span>
        </div>
        <p style="margin-bottom: 16px;">
          <strong>This code will expire in ${userData.expiryMinutes || 5} minutes.</strong>
        </p>
        <div style="background:#FEF3C7;border-left:4px solid #F59E0B;padding:16px 20px;margin:24px 0;border-radius:8px;">
          <strong>Security Notice:</strong>
          <ul style="margin:8px 0 0 20px;color:#92400E;">
            <li>Never share this code with anyone</li>
            <li>TeamSpot will never ask for this code via phone or email</li>
            <li>If you didn't request this code, you can safely ignore this email</li>
          </ul>
        </div>
      `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, '2fa')
    };
  }

  // Password reset request
  passwordResetRequest(userData) {
    return {
      EMAIL_TITLE: 'Reset Your TeamSpot Password',
      GREETING: `Hi ${userData.fullName || userData.userName},`,
      MAIN_CONTENT: `
        <p>
          We received a request to reset your password for your TeamSpot account. If you made this request, click the button below to create a new password.
        </p>
        <div class="button-container" style="text-align:center;margin:32px 0;">
          <a href="${userData.resetUrl}" class="primary-button" style="background:linear-gradient(135deg,#1e40af 0%,#1e3a8a 100%);color:#fff;text-decoration:none;padding:16px 32px;border-radius:12px;font-weight:600;font-size:16px;">
            Reset Password
          </a>
        </div>
        <div style="margin-bottom:16px;">
          If you didn't request a password reset, you can safely ignore this email. Your password won't be changed until you create a new one.
        </div>
        <div style="background:#FEF2F2;border:1px solid #F87171;border-radius:8px;padding:16px;margin-top:20px;">
          <h4 style="color:#DC2626;margin-bottom:8px;">🚨 Security Notice</h4>
          <p style="color:#DC2626;margin:0;font-size:14px;">
            If you didn't request this password reset, please contact our security team immediately at
            <a href="mailto:security@teamspot.com" style="color:#DC2626;">security@teamspot.com</a>
          </p>
        </div>
      `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, 'security')
    };
  }

  // Password changed confirmation
  passwordChangedConfirmation(userData) {
    return {
      EMAIL_TITLE: 'Your TeamSpot Password Was Changed',
      GREETING: `Hi ${userData.fullName || userData.userName},`,
      MAIN_CONTENT: `
        <p>
          This email confirms that your TeamSpot account password was successfully changed on ${userData.changeTime || new Date().toLocaleString()}.
        </p>
        <div class="content-section" style="margin:24px 0;">
          <div class="section-title" style="font-size:18px;font-weight:600;color:#1e293b;margin-bottom:12px;">🔐 Change Details</div>
          <ul style="margin-left:20px;color:#475569;">
            <li><strong>Change Date:</strong> ${userData.changeTime || new Date().toLocaleString()}</li>
            <li><strong>IP Address:</strong> ${userData.ipAddress || 'Unknown'}</li>
            <li><strong>Browser:</strong> ${userData.userAgent || 'Unknown'}</li>
            <li><strong>Location:</strong> ${userData.location || 'Unknown'}</li>
          </ul>
        </div>
        <div style="background:#FEF2F2;border:1px solid #F87171;border-radius:8px;padding:16px;margin-top:20px;">
          <h4 style="color:#DC2626;margin-bottom:8px;">🚨 Didn't Change Your Password?</h4>
          <p style="color:#DC2626;margin:0;font-size:14px;">
            If you didn't make this change, your account may have been compromised.
            <a href="mailto:security@teamspot.com" style="color:#DC2626;">Contact our security team immediately</a>
          </p>
        </div>
      `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, 'security')
    };
  }

  // Account locked notification
  accountLockedNotification(userData) {
    return {
      EMAIL_TITLE: 'Your TeamSpot Account Has Been Temporarily Locked 🔒',
      GREETING: `Hi ${userData.fullName},`,
      MAIN_CONTENT: `
                For your security, we've temporarily locked your TeamSpot account due to multiple failed login attempts.
                
                <br><br>This is a security measure to protect your account from unauthorized access.
            `,
      CONTENT_SECTIONS: [
        {
          title: '📋 What Happened?',
          content: `
                        <p style="color: #475569;">
                            We detected ${userData.attemptCount || 5} failed login attempts from IP address 
                            ${userData.ipAddress || 'Unknown'} within a short period.
                        </p>
                    `
        },
        {
          title: '🔓 How to Unlock Your Account',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li>Wait 30 minutes for automatic unlock, or</li>
                            <li>Click the button below to unlock immediately</li>
                            <li>Change your password if you suspect unauthorized access</li>
                        </ul>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'Unlock Account',
          url: userData.unlockUrl,
          primary: true
        },
        {
          text: 'Change Password',
          url: `${this.baseUrl}/reset-password`,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(userData.userId, 'security')
    };
  }

  // =====================================
  // WORKSPACE & COLLABORATION EMAILS
  // =====================================

  // Workspace invitation
  workspaceInvitation(invitationData) {
    return {
      EMAIL_TITLE: `You're Invited to Join ${invitationData.workspaceName} on TeamSpot! 🎯`,
      GREETING: `Hi ${invitationData.inviteeEmail}!`,
      MAIN_CONTENT: `
                <strong>${invitationData.inviterName}</strong> has invited you to join the 
                <strong>"${invitationData.workspaceName}"</strong> workspace on TeamSpot.
                
                <br><br>This workspace is used by their team for collaboration, project management, 
                and seamless communication. Join them to get started!
            `,
      CONTENT_SECTIONS: [
        {
          title: '🏢 Workspace Details',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Workspace:</strong> ${invitationData.workspaceName}</li>
                            <li><strong>Organization:</strong> ${invitationData.organizationName || 'Not specified'}</li>
                            <li><strong>Team Size:</strong> ${invitationData.memberCount || 'Multiple'} members</li>
                            <li><strong>Invited by:</strong> ${invitationData.inviterName} (${invitationData.inviterRole || 'Team Member'})</li>
                        </ul>
                    `
        },
        {
          title: "💼 What You'll Get Access To",
          content: `
                        <p style="color: #475569;">
                            Once you join, you'll be able to participate in team discussions, access shared files, 
                            join meetings, collaborate on projects, and stay updated with all team activities.
                        </p>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'Accept Invitation',
          url: invitationData.acceptUrl,
          primary: true
        },
        {
          text: 'View Workspace',
          url: invitationData.previewUrl,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
                <div style="background: #F0FDF4; border: 1px solid #86EFAC; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <p style="color: #166534; margin: 0; font-size: 14px;">
                        <strong>New to TeamSpot?</strong> Don't worry! We'll guide you through the setup process 
                        and help you get familiar with all the features.
                    </p>
                </div>
            `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(invitationData.inviteeId, 'invitations')
    };
  }

  // New member joined workspace
  memberJoinedWorkspace(memberData) {
    return {
      EMAIL_TITLE: `${memberData.memberName} Joined Your Workspace! 👋`,
      GREETING: `Hi ${memberData.recipientName}!`,
      MAIN_CONTENT: `
                Great news! <strong>${memberData.memberName}</strong> just joined the 
                <strong>"${memberData.workspaceName}"</strong> workspace.
                
                <br><br>Say hello and help them get started with the team!
            `,
      CONTENT_SECTIONS: [
        {
          title: '👤 New Member Profile',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Name:</strong> ${memberData.memberName}</li>
                            <li><strong>Email:</strong> ${memberData.memberEmail}</li>
                            <li><strong>Role:</strong> ${memberData.memberRole || 'Team Member'}</li>
                            <li><strong>Department:</strong> ${memberData.department || 'Not specified'}</li>
                            <li><strong>Joined:</strong> ${memberData.joinDate || new Date().toLocaleDateString()}</li>
                        </ul>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'View Workspace',
          url: `${this.baseUrl}/workspace/${memberData.workspaceId}`,
          primary: true
        },
        {
          text: 'Send Welcome Message',
          url: `${this.baseUrl}/chat/user/${memberData.memberId}`,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(memberData.recipientId, 'workspace-updates')
    };
  }

  // =====================================
  // MEETING & SCHEDULING EMAILS
  // =====================================

  // Meeting invitation
  meetingInvitation(meetingData) {
    return {
      EMAIL_TITLE: `Meeting Invitation: ${meetingData.meetingTitle} 📅`,
      GREETING: `Hi ${meetingData.attendeeName}!`,
      MAIN_CONTENT: `
                <strong>${meetingData.organizerName}</strong> has invited you to a meeting on TeamSpot.
                
                <br><br>Please review the meeting details below and confirm your attendance.
            `,
      CONTENT_SECTIONS: [
        {
          title: '📅 Meeting Details',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Title:</strong> ${meetingData.meetingTitle}</li>
                            <li><strong>Date:</strong> ${meetingData.meetingDate}</li>
                            <li><strong>Time:</strong> ${meetingData.meetingTime} (${meetingData.timezone || 'Your timezone'})</li>
                            <li><strong>Duration:</strong> ${meetingData.duration || '1 hour'}</li>
                            <li><strong>Organizer:</strong> ${meetingData.organizerName}</li>
                            <li><strong>Meeting Type:</strong> ${meetingData.meetingType || 'Video Conference'}</li>
                        </ul>
                    `
        },
        {
          title: '📋 Agenda',
          content:
            meetingData.agenda ||
            `
                        <p style="color: #475569;">
                            The organizer will share the agenda closer to the meeting time.
                        </p>
                    `
        },
        {
          title: '👥 Attendees',
          content: `
                        <p style="color: #475569;">
                            ${meetingData.attendeeCount || 'Several'} team members have been invited to this meeting.
                        </p>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'Accept',
          url: meetingData.acceptUrl,
          primary: true
        },
        {
          text: 'Decline',
          url: meetingData.declineUrl,
          primary: false
        },
        {
          text: 'Maybe',
          url: meetingData.maybeUrl,
          primary: false
        }
      ],
      ATTACHMENTS: meetingData.attachments,
      ADDITIONAL_CONTENT: `
                <div style="background: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <h4 style="color: #92400E; margin-bottom: 8px;">📱 Join on Mobile</h4>
                    <p style="color: #92400E; margin: 0; font-size: 14px;">
                        Download the TeamSpot mobile app to join this meeting from anywhere. 
                        You'll receive a reminder 15 minutes before the meeting starts.
                    </p>
                </div>
            `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(meetingData.attendeeId, 'meetings')
    };
  }

  // Meeting reminder
  meetingReminder(meetingData) {
    return {
      EMAIL_TITLE: `Reminder: ${meetingData.meetingTitle} starts in ${meetingData.timeUntil} ⏰`,
      GREETING: `Hi ${meetingData.attendeeName}!`,
      MAIN_CONTENT: `
                This is a friendly reminder that you have an upcoming meeting in ${meetingData.timeUntil}.
                
                <br><br>Make sure you're ready to join on time!
            `,
      CONTENT_SECTIONS: [
        {
          title: '📅 Quick Details',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Meeting:</strong> ${meetingData.meetingTitle}</li>
                            <li><strong>Starts:</strong> ${meetingData.startTime}</li>
                            <li><strong>Duration:</strong> ${meetingData.duration}</li>
                            <li><strong>Status:</strong> ${meetingData.status || 'Confirmed'}</li>
                        </ul>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'Join Meeting Now',
          url: meetingData.joinUrl,
          primary: true
        },
        {
          text: 'View Details',
          url: meetingData.detailsUrl,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(meetingData.attendeeId, 'meeting-reminders')
    };
  }

  // Meeting canceled
  meetingCanceled(meetingData) {
    return {
      EMAIL_TITLE: `Meeting Canceled: ${meetingData.meetingTitle} ❌`,
      GREETING: `Hi ${meetingData.attendeeName}!`,
      MAIN_CONTENT: `
                <strong>${meetingData.organizerName}</strong> has canceled the meeting "${meetingData.meetingTitle}" 
                that was scheduled for ${meetingData.originalDateTime}.
                
                <br><br>${meetingData.cancellationReason || 'No specific reason was provided.'}
            `,
      CONTENT_SECTIONS: [
        {
          title: '📅 Canceled Meeting Details',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Original Date:</strong> ${meetingData.originalDateTime}</li>
                            <li><strong>Meeting Title:</strong> ${meetingData.meetingTitle}</li>
                            <li><strong>Organizer:</strong> ${meetingData.organizerName}</li>
                            <li><strong>Canceled On:</strong> ${meetingData.canceledDateTime || new Date().toLocaleString()}</li>
                        </ul>
                    `
        }
      ],
      BUTTONS: meetingData.rescheduleUrl
        ? [
            {
              text: 'Reschedule Meeting',
              url: meetingData.rescheduleUrl,
              primary: true
            }
          ]
        : [],
      ADDITIONAL_CONTENT: `
                <div style="background: #FEF2F2; border: 1px solid #FECACA; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <p style="color: #991B1B; margin: 0; font-size: 14px;">
                        This meeting has been removed from your calendar. If you need to discuss the original agenda items, 
                        feel free to reach out to ${meetingData.organizerName} directly.
                    </p>
                </div>
            `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(meetingData.attendeeId, 'meetings')
    };
  }

  // =====================================
  // PROJECT & TASK NOTIFICATIONS
  // =====================================

  // Project assignment
  projectAssignment(projectData) {
    return {
      EMAIL_TITLE: `You've Been Assigned to Project: ${projectData.projectName} 🎯`,
      GREETING: `Hi ${projectData.assigneeName}!`,
      MAIN_CONTENT: `
                <strong>${projectData.assignerName}</strong> has assigned you to the project 
                <strong>"${projectData.projectName}"</strong>.
                
                <br><br>Check out the project details below and get started!
            `,
      CONTENT_SECTIONS: [
        {
          title: '📊 Project Overview',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Project:</strong> ${projectData.projectName}</li>
                            <li><strong>Due Date:</strong> ${projectData.dueDate}</li>
                            <li><strong>Priority:</strong> ${projectData.priority || 'Medium'}</li>
                            <li><strong>Project Manager:</strong> ${projectData.projectManager}</li>
                            <li><strong>Team Size:</strong> ${projectData.teamSize || 'Multiple'} members</li>
                            <li><strong>Status:</strong> ${projectData.status || 'Active'}</li>
                        </ul>
                    `
        },
        {
          title: '📝 Description',
          content:
            projectData.description ||
            `
                        <p style="color: #475569;">
                            Project details will be shared in the project workspace. 
                            Click the button below to access all project materials.
                        </p>
                    `
        }
      ],
      FEATURE_CARDS: [
        {
          icon: '📋',
          title: 'Task Management',
          description: 'Track your tasks and deadlines'
        },
        {
          icon: '💬',
          title: 'Team Chat',
          description: 'Communicate with team members'
        },
        {
          icon: '📁',
          title: 'File Sharing',
          description: 'Access project documents'
        }
      ],
      BUTTONS: [
        {
          text: 'View Project',
          url: `${this.baseUrl}/projects/${projectData.projectId}`,
          primary: true
        },
        {
          text: 'Join Project Chat',
          url: `${this.baseUrl}/projects/${projectData.projectId}/chat`,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(projectData.assigneeId, 'project-updates')
    };
  }

  // Task assignment
  taskAssignment(taskData) {
    return {
      EMAIL_TITLE: `New Task Assigned: ${taskData.taskTitle} ✅`,
      GREETING: `Hi ${taskData.assigneeName}!`,
      MAIN_CONTENT: `
                You have been assigned a new task by <strong>${taskData.assignerName}</strong>.
                
                <br><br>Please review the task details and update your progress as you work on it.
            `,
      CONTENT_SECTIONS: [
        {
          title: '📋 Task Details',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Task:</strong> ${taskData.taskTitle}</li>
                            <li><strong>Project:</strong> ${taskData.projectName || 'Individual Task'}</li>
                            <li><strong>Due Date:</strong> ${taskData.dueDate}</li>
                            <li><strong>Priority:</strong> ${taskData.priority || 'Medium'}</li>
                            <li><strong>Estimated Time:</strong> ${taskData.estimatedHours || 'Not specified'}</li>
                            <li><strong>Assigned by:</strong> ${taskData.assignerName}</li>
                        </ul>
                    `
        },
        {
          title: '📄 Task Description',
          content:
            taskData.description ||
            `
                        <p style="color: #475569;">
                            No additional description provided. Contact ${taskData.assignerName} for more details if needed.
                        </p>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'View Task',
          url: `${this.baseUrl}/tasks/${taskData.taskId}`,
          primary: true
        },
        {
          text: 'Update Progress',
          url: `${this.baseUrl}/tasks/${taskData.taskId}/progress`,
          primary: false
        }
      ],
      ATTACHMENTS: taskData.attachments,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(taskData.assigneeId, 'task-updates')
    };
  }

  // Task deadline reminder
  taskDeadlineReminder(taskData) {
    return {
      EMAIL_TITLE: `Task Deadline Approaching: ${taskData.taskTitle} ⏰`,
      GREETING: `Hi ${taskData.assigneeName}!`,
      MAIN_CONTENT: `
                This is a reminder that your task <strong>"${taskData.taskTitle}"</strong> is due 
                ${taskData.timeRemaining}.
                
                <br><br>Current progress: <strong>${taskData.progress || '0'}%</strong> complete.
            `,
      CONTENT_SECTIONS: [
        {
          title: '📅 Deadline Information',
          content: `
                        <ul style="margin-left: 20px; color: #475569;">
                            <li><strong>Due Date:</strong> ${taskData.dueDate}</li>
                            <li><strong>Time Remaining:</strong> ${taskData.timeRemaining}</li>
                            <li><strong>Current Status:</strong> ${taskData.status || 'In Progress'}</li>
                            <li><strong>Project:</strong> ${taskData.projectName || 'Individual Task'}</li>
                        </ul>
                    `
        }
      ],
      BUTTONS: [
        {
          text: 'Complete Task',
          url: `${this.baseUrl}/tasks/${taskData.taskId}`,
          primary: true
        },
        {
          text: 'Request Extension',
          url: `${this.baseUrl}/tasks/${taskData.taskId}/extend`,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: taskData.isOverdue
        ? `
                <div style="background: #FEF2F2; border: 1px solid #F87171; border-radius: 8px; padding: 16px; margin-top: 20px;">
                    <h4 style="color: #DC2626; margin-bottom: 8px;">🚨 Task Overdue</h4>
                    <p style="color: #DC2626; margin: 0; font-size: 14px;">
                        This task is now ${taskData.overdueDays} day(s) overdue. Please update your progress or 
                        contact your project manager if you need assistance.
                    </p>
                </div>
            `
        : '',
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(taskData.assigneeId, 'task-reminders')
    };
  }

  // =====================================
  // NOTIFICATION EMAILS
  // =====================================

  // General notification
  // General notification
  generalNotification(notificationData) {
    return {
      EMAIL_TITLE: notificationData.title,
      GREETING: `Hi ${notificationData.recipientName}!`,
      MAIN_CONTENT: notificationData.message,
      CONTENT_SECTIONS: notificationData.sections || [],
      BUTTONS: notificationData.buttons || [],
      ADDITIONAL_CONTENT: notificationData.additionalContent || '',
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(notificationData.recipientId, 'notifications')
    };
  }

  // Mention notification
  mentionNotification(mentionData) {
    return {
      EMAIL_TITLE: `You were mentioned in ${mentionData.channelName} 💬`,
      GREETING: `Hi ${mentionData.recipientName}!`,
      MAIN_CONTENT: `
            <strong>${mentionData.mentionerName}</strong> mentioned you in 
            <strong>#${mentionData.channelName}</strong> in the ${mentionData.workspaceName} workspace.
            
            <br><br>Here's what they said:
        `,
      CONTENT_SECTIONS: [
        {
          title: '💬 Message Preview',
          content: `
                    <div style="background: #F8FAFC; border-left: 4px solid #3B82F6; padding: 16px; margin: 16px 0;">
                        <p style="color: #475569; font-style: italic; margin: 0;">
                            "${mentionData.messagePreview}"
                        </p>
                        <p style="color: #6B7280; font-size: 12px; margin: 8px 0 0 0;">
                            Posted at ${mentionData.timestamp}
                        </p>
                    </div>
                `
        },
        {
          title: '📍 Context',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Workspace:</strong> ${mentionData.workspaceName}</li>
                        <li><strong>Channel:</strong> #${mentionData.channelName}</li>
                        <li><strong>Thread:</strong> ${mentionData.threadTitle || 'General discussion'}</li>
                        <li><strong>Participants:</strong> ${mentionData.participantCount || 'Multiple'} people</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'Reply to Message',
          url: mentionData.replyUrl,
          primary: true
        },
        {
          text: 'View Channel',
          url: mentionData.channelUrl,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(mentionData.recipientId, 'mentions')
    };
  }

  // File share notification
  fileShareNotification(fileData) {
    return {
      EMAIL_TITLE: `${fileData.sharerName} shared a file with you 📎`,
      GREETING: `Hi ${fileData.recipientName}!`,
      MAIN_CONTENT: `
            <strong>${fileData.sharerName}</strong> has shared a file with you in the 
            ${fileData.workspaceName} workspace.
            
            <br><br>You now have access to view and download this file.
        `,
      CONTENT_SECTIONS: [
        {
          title: '📁 File Details',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>File Name:</strong> ${fileData.fileName}</li>
                        <li><strong>File Type:</strong> ${fileData.fileType}</li>
                        <li><strong>File Size:</strong> ${fileData.fileSize}</li>
                        <li><strong>Shared by:</strong> ${fileData.sharerName}</li>
                        <li><strong>Shared on:</strong> ${fileData.shareDate}</li>
                        <li><strong>Location:</strong> ${fileData.folderPath || 'Root folder'}</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'View File',
          url: fileData.viewUrl,
          primary: true
        },
        {
          text: 'Download',
          url: fileData.downloadUrl,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: fileData.message
        ? `
            <div style="background: #F0F9FF; border: 1px solid #BAE6FD; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #0369A1; margin-bottom: 8px;">💬 Message from ${fileData.sharerName}</h4>
                <p style="color: #0369A1; margin: 0; font-size: 14px;">
                    "${fileData.message}"
                </p>
            </div>
        `
        : '',
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(fileData.recipientId, 'file-shares')
    };
  }

  // =====================================
  // BILLING & SUBSCRIPTION EMAILS
  // =====================================

  // Payment successful
  paymentSuccessful(paymentData) {
    return {
      EMAIL_TITLE: 'Payment Successful - Thank You! 💳',
      GREETING: `Hi ${paymentData.customerName}!`,
      MAIN_CONTENT: `
            Thank you for your payment! Your transaction has been processed successfully and your 
            TeamSpot subscription is now active.
            
            <br><br>Here are your payment details:
        `,
      CONTENT_SECTIONS: [
        {
          title: '🧾 Payment Details',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Amount:</strong> $${paymentData.amount}</li>
                        <li><strong>Plan:</strong> ${paymentData.planName}</li>
                        <li><strong>Billing Period:</strong> ${paymentData.billingPeriod}</li>
                        <li><strong>Transaction ID:</strong> ${paymentData.transactionId}</li>
                        <li><strong>Payment Method:</strong> ${paymentData.paymentMethod}</li>
                        <li><strong>Date:</strong> ${paymentData.paymentDate}</li>
                        <li><strong>Next Billing:</strong> ${paymentData.nextBillingDate}</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'View Invoice',
          url: paymentData.invoiceUrl,
          primary: true
        },
        {
          text: 'Manage Subscription',
          url: `${this.baseUrl}/billing`,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
            <div style="background: #F0FDF4; border: 1px solid #86EFAC; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #166534; margin-bottom: 8px;">🎉 What's Next?</h4>
                <p style="color: #166534; margin: 0; font-size: 14px;">
                    Your subscription is now active! Enjoy all premium features and unlimited access to TeamSpot's collaboration tools.
                </p>
            </div>
        `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(paymentData.customerId, 'billing')
    };
  }

  // Payment failed
  paymentFailed(paymentData) {
    return {
      EMAIL_TITLE: 'Payment Failed - Action Required ⚠️',
      GREETING: `Hi ${paymentData.customerName},`,
      MAIN_CONTENT: `
            We were unable to process your payment for your TeamSpot subscription. 
            Please update your payment method to avoid any service interruption.
            
            <br><br>Your account will remain active for ${paymentData.gracePeriod || '7 days'} 
            while you resolve this issue.
        `,
      CONTENT_SECTIONS: [
        {
          title: '💳 Payment Information',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Amount:</strong> $${paymentData.amount}</li>
                        <li><strong>Plan:</strong> ${paymentData.planName}</li>
                        <li><strong>Payment Method:</strong> ${paymentData.paymentMethod}</li>
                        <li><strong>Failure Reason:</strong> ${paymentData.failureReason}</li>
                        <li><strong>Retry Date:</strong> ${paymentData.retryDate}</li>
                    </ul>
                `
        },
        {
          title: '🔧 How to Fix This',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li>Update your payment method in billing settings</li>
                        <li>Ensure your card has sufficient funds</li>
                        <li>Check that your billing address is correct</li>
                        <li>Contact your bank if the issue persists</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'Update Payment Method',
          url: `${this.baseUrl}/billing/payment-methods`,
          primary: true
        },
        {
          text: 'Retry Payment',
          url: paymentData.retryUrl,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
            <div style="background: #FEF2F2; border: 1px solid #F87171; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #DC2626; margin-bottom: 8px;">⏰ Important</h4>
                <p style="color: #DC2626; margin: 0; font-size: 14px;">
                    If payment is not resolved within ${paymentData.gracePeriod || '7 days'}, 
                    your account will be downgraded to the free plan and some features will be limited.
                </p>
            </div>
        `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(paymentData.customerId, 'billing')
    };
  }

  // Subscription renewal reminder
  subscriptionRenewalReminder(subscriptionData) {
    return {
      EMAIL_TITLE: `Your TeamSpot Subscription Renews in ${subscriptionData.daysUntilRenewal} Days 📅`,
      GREETING: `Hi ${subscriptionData.customerName}!`,
      MAIN_CONTENT: `
            This is a friendly reminder that your TeamSpot subscription will automatically renew 
            on ${subscriptionData.renewalDate}.
            
            <br><br>We'll charge your selected payment method for the next billing period.
        `,
      CONTENT_SECTIONS: [
        {
          title: '📋 Subscription Details',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Plan:</strong> ${subscriptionData.planName}</li>
                        <li><strong>Price:</strong> $${subscriptionData.amount}/${subscriptionData.billingPeriod}</li>
                        <li><strong>Renewal Date:</strong> ${subscriptionData.renewalDate}</li>
                        <li><strong>Payment Method:</strong> ${subscriptionData.paymentMethod}</li>
                        <li><strong>Users:</strong> ${subscriptionData.userCount} active users</li>
                    </ul>
                `
        }
      ],
      FEATURE_CARDS: [
        {
          icon: '✨',
          title: 'Premium Features',
          description: 'Unlimited storage and advanced tools'
        },
        {
          icon: '🔒',
          title: 'Enhanced Security',
          description: 'Advanced security and compliance features'
        },
        {
          icon: '📞',
          title: 'Priority Support',
          description: '24/7 dedicated customer support'
        }
      ],
      BUTTONS: [
        {
          text: 'Manage Subscription',
          url: `${this.baseUrl}/billing`,
          primary: true
        },
        {
          text: 'Update Payment Method',
          url: `${this.baseUrl}/billing/payment-methods`,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(subscriptionData.customerId, 'billing-reminders')
    };
  }

  // Subscription canceled
  subscriptionCanceled(subscriptionData) {
    return {
      EMAIL_TITLE: 'Your TeamSpot Subscription Has Been Canceled 😢',
      GREETING: `Hi ${subscriptionData.customerName},`,
      MAIN_CONTENT: `
            We're sorry to see you go! Your TeamSpot subscription has been successfully canceled 
            as requested on ${subscriptionData.cancellationDate}.
            
            <br><br>Your account will remain active until ${subscriptionData.accessEndDate}, 
            after which you'll be moved to our free plan.
        `,
      CONTENT_SECTIONS: [
        {
          title: '📅 Important Dates',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Cancellation Date:</strong> ${subscriptionData.cancellationDate}</li>
                        <li><strong>Access Ends:</strong> ${subscriptionData.accessEndDate}</li>
                        <li><strong>Last Billing:</strong> ${subscriptionData.lastBillingDate}</li>
                        <li><strong>Reason:</strong> ${subscriptionData.cancellationReason || 'Not specified'}</li>
                    </ul>
                `
        },
        {
          title: '💾 What Happens to Your Data',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li>Your workspaces and files remain safe</li>
                        <li>You can export your data anytime before ${subscriptionData.accessEndDate}</li>
                        <li>Free plan limits will apply after the access period</li>
                        <li>Premium features will be disabled</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'Reactivate Subscription',
          url: `${this.baseUrl}/billing/reactivate`,
          primary: true
        },
        {
          text: 'Export Data',
          url: `${this.baseUrl}/export`,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
            <div style="background: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #92400E; margin-bottom: 8px;">💡 Changed Your Mind?</h4>
                <p style="color: #92400E; margin: 0; font-size: 14px;">
                    You can reactivate your subscription anytime before ${subscriptionData.accessEndDate} 
                    without losing any data or settings. We'd love to have you back!
                </p>
            </div>
        `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(subscriptionData.customerId, 'billing')
    };
  }

  // =====================================
  // SYSTEM & MAINTENANCE EMAILS
  // =====================================

  // Scheduled maintenance
  scheduledMaintenance(maintenanceData) {
    return {
      EMAIL_TITLE: `Scheduled Maintenance: ${maintenanceData.maintenanceTitle} 🔧`,
      GREETING: `Hi ${maintenanceData.fullName}!`,
      MAIN_CONTENT: `
            We're performing scheduled maintenance on TeamSpot to improve performance and add new features.
            
            <br><br>During this time, some services may be temporarily unavailable.
        `,
      CONTENT_SECTIONS: [
        {
          title: '🕐 Maintenance Schedule',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Start Time:</strong> ${maintenanceData.startTime}</li>
                        <li><strong>End Time:</strong> ${maintenanceData.endTime}</li>
                        <li><strong>Duration:</strong> ${maintenanceData.duration}</li>
                        <li><strong>Timezone:</strong> ${maintenanceData.timezone || 'UTC'}</li>
                        <li><strong>Type:</strong> ${maintenanceData.maintenanceType || 'System Update'}</li>
                    </ul>
                `
        },
        {
          title: '⚠️ Expected Impact',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        ${maintenanceData.impactedServices?.map((service) => `<li><strong>${service.name}:</strong> ${service.impact}</li>`).join('') || '<li>Minimal service disruption expected</li>'}
                    </ul>
                `
        },
        {
          title: "✨ What's New",
          content: `
                    <p style="color: #475569;">
                        ${maintenanceData.improvements || 'Performance improvements and bug fixes to enhance your TeamSpot experience.'}
                    </p>
                `
        }
      ],
      BUTTONS: [
        {
          text: 'View Status Page',
          url: `${this.baseUrl}/status`,
          primary: true
        }
      ],
      ADDITIONAL_CONTENT: `
            <div style="background: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #92400E; margin-bottom: 8px;">📱 Mobile App Users</h4>
                <p style="color: #92400E; margin: 0; font-size: 14px;">
                    The mobile app may continue to work with limited functionality. 
                    We recommend updating to the latest version after maintenance is complete.
                </p>
            </div>
        `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(maintenanceData.recipientId, 'system-updates')
    };
  }

  // Security alert
  securityAlert(securityData) {
    return {
      EMAIL_TITLE: `Security Alert: ${securityData.alertType} 🔐`,
      GREETING: `Hi ${securityData.fullName},`,
      MAIN_CONTENT: `
            We detected ${securityData.alertDescription} on your TeamSpot account.
            
            <br><br>Please review the details below and take appropriate action if necessary.
        `,
      CONTENT_SECTIONS: [
        {
          title: '🔍 Alert Details',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Alert Type:</strong> ${securityData.alertType}</li>
                        <li><strong>Time:</strong> ${securityData.alertTime}</li>
                        <li><strong>IP Address:</strong> ${securityData.ipAddress}</li>
                        <li><strong>Location:</strong> ${securityData.location || 'Unknown'}</li>
                        <li><strong>Device:</strong> ${securityData.device || 'Unknown'}</li>
                        <li><strong>Browser:</strong> ${securityData.browser || 'Unknown'}</li>
                    </ul>
                `
        },
        {
          title: '🛡️ Recommended Actions',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li>Change your password immediately if this wasn't you</li>
                        <li>Enable two-factor authentication</li>
                        <li>Review your recent account activity</li>
                        <li>Sign out of all sessions if concerned</li>
                    </ul>
                `
        }
      ],
      BUTTONS: [
        {
          text: securityData.wasYou ? 'This Was Me' : 'Secure My Account',
          url: securityData.wasYou ? securityData.confirmUrl : securityData.secureUrl,
          primary: true
        },
        {
          text: 'View Account Activity',
          url: `${this.baseUrl}/security/activity`,
          primary: false
        }
      ],
      ADDITIONAL_CONTENT: `
            <div style="background: #FEF2F2; border: 1px solid #F87171; border-radius: 8px; padding: 16px; margin-top: 20px;">
                <h4 style="color: #DC2626; margin-bottom: 8px;">🚨 If This Wasn't You</h4>
                <p style="color: #DC2626; margin: 0; font-size: 14px;">
                    Immediately change your password and contact our security team at 
                    <a href="mailto:security@teamspot.com" style="color: #DC2626;">security@teamspot.com</a>. 
                    We'll help secure your account right away.
                </p>
            </div>
        `,
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(securityData.recipientId, 'security-alerts')
    };
  }

  // =====================================
  // WEEKLY/MONTHLY DIGEST EMAILS
  // =====================================

  // Weekly activity digest
  weeklyDigest(digestData) {
    return {
      EMAIL_TITLE: `Your TeamSpot Weekly Digest 📊`,
      GREETING: `Hi ${digestData.recipientName}!`,
      MAIN_CONTENT: `
            Here's a summary of your team's activity in TeamSpot for the week of 
            ${digestData.weekStart} - ${digestData.weekEnd}.
            
            <br><br>Great work this week! 🎉
        `,
      CONTENT_SECTIONS: [
        {
          title: "📈 This Week's Highlights",
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Messages sent:</strong> ${digestData.messagesSent || 0}</li>
                        <li><strong>Tasks completed:</strong> ${digestData.tasksCompleted || 0}</li>
                        <li><strong>Meetings attended:</strong> ${digestData.meetingsAttended || 0}</li>
                        <li><strong>Files shared:</strong> ${digestData.filesShared || 0}</li>
                        <li><strong>Projects updated:</strong> ${digestData.projectsUpdated || 0}</li>
                        <li><strong>Active days:</strong> ${digestData.activeDays || 0}/7</li>
                    </ul>
                `
        },
        {
          title: '🏆 Top Achievements',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        ${digestData.achievements?.map((achievement) => `<li><strong>${achievement.title}:</strong> ${achievement.description}</li>`).join('') || '<li>Keep up the great work!</li>'}
                    </ul>
                `
        },
        {
          title: '📅 Upcoming This Week',
          content: `
                    <ul style="margin-left: 20px; color: #475569;">
                        <li><strong>Upcoming meetings:</strong> ${digestData.upcomingMeetings || 0}</li>
                        <li><strong>Task deadlines:</strong> ${digestData.upcomingDeadlines || 0}</li>
                        <li><strong>Project milestones:</strong> ${digestData.upcomingMilestones || 0}</li>
                    </ul>
                `
        }
      ],
      FEATURE_CARDS:
        digestData.topWorkspaces?.map((workspace) => ({
          icon: '🏢',
          title: workspace.name,
          description: `${workspace.activity} activities this week`
        })) || [],
      BUTTONS: [
        {
          text: 'View Full Dashboard',
          url: `${this.baseUrl}/dashboard`,
          primary: true
        },
        {
          text: 'Team Analytics',
          url: `${this.baseUrl}/analytics`,
          primary: false
        }
      ],
      UNSUBSCRIBE_LINK: this.generateUnsubscribeLink(digestData.recipientId, 'weekly-digest')
    };
  }

  // =====================================
  // UTILITY METHODS
  // =====================================

  // Generate footer content
  generateFooterContent(unsubscribeLink) {
    return `
        <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #E5E7EB; color: #6B7280; font-size: 12px;">
            <p>This email was sent by TeamSpot. If you no longer wish to receive these emails, 
            <a href="${unsubscribeLink}" style="color: #6B7280;">unsubscribe here</a>.</p>
            <p>TeamSpot Inc. | 123 Business Ave, Suite 100 | San Francisco, CA 94105</p>
            <p>Questions? Contact us at <a href="mailto:${this.supportEmail}" style="color: #6B7280;">${this.supportEmail}</a></p>
        </div>
    `;
  }

  // Generate email signature
  generateSignature(senderName = 'TeamSpot Team') {
    return `
        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #E5E7EB;">
            <p style="margin: 0; color: #374151;">Best regards,<br>
            <strong>${senderName}</strong></p>
            <p style="margin: 8px 0 0 0; color: #6B7280; font-size: 14px;">
                <a href="${this.baseUrl}" style="color: #3B82F6; text-decoration: none;">TeamSpot.com</a> | 
                Making teamwork seamless
            </p>
        </div>
    `;
  }

  // Format content with proper styling
  formatContent(content, type = 'html') {
    if (type === 'plain') {
      return content.replace(/<[^>]*>/g, '').replace(/\n\s*\n/g, '\n');
    }

    return content
      .replace(/\n/g, '<br>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>');
  }

  // Validate email data
  validateEmailData(emailType, data) {
    const requiredFields = {
      welcome: ['fullName', 'userId'],
      emailVerification: ['fullName', 'verificationUrl', 'userId'],
      passwordReset: ['fullName', 'resetUrl', 'userId'],
      meetingInvitation: ['attendeeName', 'organizerName', 'meetingTitle', 'meetingDate', 'meetingTime'],
      taskAssignment: ['assigneeName', 'taskTitle', 'dueDate', 'assignerName'],
      workspaceInvitation: ['inviteeEmail', 'workspaceName', 'inviterName', 'acceptUrl']
    };

    const required = requiredFields[emailType];
    if (!required) return true;

    return required.every((field) => data.hasOwnProperty(field) && data[field] !== null && data[field] !== '');
  }
}

// Export the EmailContentGenerator class
export default EmailContentGenerator;
