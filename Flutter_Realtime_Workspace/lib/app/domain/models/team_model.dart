class TeamMemberPermissions {
  final bool canCreateProjects;
  final bool canDeleteProjects;
  final bool canManageMembers;
  final bool canInviteMembers;
  final bool canChangeSettings;
  final bool canViewAllProjects;
  final bool canExportData;
  final bool canManageIntegrations;

  const TeamMemberPermissions({
    this.canCreateProjects = false,
    this.canDeleteProjects = false,
    this.canManageMembers = false,
    this.canInviteMembers = false,
    this.canChangeSettings = false,
    this.canViewAllProjects = true,
    this.canExportData = false,
    this.canManageIntegrations = false,
  });

  factory TeamMemberPermissions.fromJson(Map<String, dynamic> json) =>
      TeamMemberPermissions(
        canCreateProjects: json['canCreateProjects'] ?? false,
        canDeleteProjects: json['canDeleteProjects'] ?? false,
        canManageMembers: json['canManageMembers'] ?? false,
        canInviteMembers: json['canInviteMembers'] ?? false,
        canChangeSettings: json['canChangeSettings'] ?? false,
        canViewAllProjects: json['canViewAllProjects'] ?? true,
        canExportData: json['canExportData'] ?? false,
        canManageIntegrations: json['canManageIntegrations'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'canCreateProjects': canCreateProjects,
        'canDeleteProjects': canDeleteProjects,
        'canManageMembers': canManageMembers,
        'canInviteMembers': canInviteMembers,
        'canChangeSettings': canChangeSettings,
        'canViewAllProjects': canViewAllProjects,
        'canExportData': canExportData,
        'canManageIntegrations': canManageIntegrations,
      };
}

class TeamMemberNotificationSettings {
  final bool email;
  final bool push;
  final bool projectUpdates;
  final bool mentions;

  const TeamMemberNotificationSettings({
    this.email = true,
    this.push = true,
    this.projectUpdates = true,
    this.mentions = true,
  });

  factory TeamMemberNotificationSettings.fromJson(
          Map<String, dynamic> json) =>
      TeamMemberNotificationSettings(
        email: json['email'] ?? true,
        push: json['push'] ?? true,
        projectUpdates: json['projectUpdates'] ?? true,
        mentions: json['mentions'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'push': push,
        'projectUpdates': projectUpdates,
        'mentions': mentions,
      };
}

class TeamMember {
  final String userId;
  // role: owner | admin | manager | member | viewer | guest
  final String role;
  final TeamMemberPermissions permissions;
  final DateTime joinedAt;
  final String? invitedBy;
  // status: active | invited | suspended | removed
  final String status;
  final DateTime? lastActive;
  final TeamMemberNotificationSettings notificationSettings;

  const TeamMember({
    required this.userId,
    this.role = 'member',
    this.permissions = const TeamMemberPermissions(),
    required this.joinedAt,
    this.invitedBy,
    this.status = 'active',
    this.lastActive,
    this.notificationSettings = const TeamMemberNotificationSettings(),
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        role: json['role'] ?? 'member',
        permissions: json['permissions'] != null
            ? TeamMemberPermissions.fromJson(json['permissions'])
            : const TeamMemberPermissions(),
        joinedAt:
            DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
        invitedBy: json['invitedBy'] is Map
            ? json['invitedBy']['_id']
            : json['invitedBy'],
        status: json['status'] ?? 'active',
        lastActive: json['lastActive'] != null
            ? DateTime.tryParse(json['lastActive'])
            : null,
        notificationSettings: json['notificationSettings'] != null
            ? TeamMemberNotificationSettings.fromJson(
                json['notificationSettings'])
            : const TeamMemberNotificationSettings(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'permissions': permissions.toJson(),
        'joinedAt': joinedAt.toIso8601String(),
        'invitedBy': invitedBy,
        'status': status,
        'lastActive': lastActive?.toIso8601String(),
        'notificationSettings': notificationSettings.toJson(),
      };
}

class TeamInvite {
  final String email;
  final String? role;
  final String? invitedBy;
  final String? token;
  final String? message;
  final DateTime? invitedAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  // status: pending | accepted | expired | cancelled
  final String status;

  const TeamInvite({
    required this.email,
    this.role,
    this.invitedBy,
    this.token,
    this.message,
    this.invitedAt,
    this.expiresAt,
    this.acceptedAt,
    this.status = 'pending',
  });

  factory TeamInvite.fromJson(Map<String, dynamic> json) => TeamInvite(
        email: json['email'] ?? '',
        role: json['role'],
        invitedBy: json['invitedBy'] is Map
            ? json['invitedBy']['_id']
            : json['invitedBy'],
        token: json['token'],
        message: json['message'],
        invitedAt: json['invitedAt'] != null
            ? DateTime.tryParse(json['invitedAt'])
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'])
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.tryParse(json['acceptedAt'])
            : null,
        status: json['status'] ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'role': role,
        'invitedBy': invitedBy,
        'token': token,
        'message': message,
        'invitedAt': invitedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'status': status,
      };
}

class TeamSettings {
  final bool isPublic;
  final bool requireApprovalForJoining;
  final bool allowMemberInvites;
  final String? defaultProjectTemplate;
  final String? timezone;
  final List<String> workingDays;

  const TeamSettings({
    this.isPublic = false,
    this.requireApprovalForJoining = false,
    this.allowMemberInvites = true,
    this.defaultProjectTemplate,
    this.timezone,
    this.workingDays = const [],
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) => TeamSettings(
        isPublic: json['isPublic'] ?? false,
        requireApprovalForJoining: json['requireApprovalForJoining'] ?? false,
        allowMemberInvites: json['allowMemberInvites'] ?? true,
        defaultProjectTemplate: json['defaultProjectTemplate'],
        timezone: json['timezone'],
        workingDays: List<String>.from(json['workingDays'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'isPublic': isPublic,
        'requireApprovalForJoining': requireApprovalForJoining,
        'allowMemberInvites': allowMemberInvites,
        'defaultProjectTemplate': defaultProjectTemplate,
        'timezone': timezone,
        'workingDays': workingDays,
      };
}

class TeamStats {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int totalMembers;
  final int activeMembers;
  final DateTime? lastActivityAt;

  const TeamStats({
    this.totalProjects = 0,
    this.activeProjects = 0,
    this.completedProjects = 0,
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.lastActivityAt,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) => TeamStats(
        totalProjects: json['totalProjects'] ?? 0,
        activeProjects: json['activeProjects'] ?? 0,
        completedProjects: json['completedProjects'] ?? 0,
        totalMembers: json['totalMembers'] ?? 0,
        activeMembers: json['activeMembers'] ?? 0,
        lastActivityAt: json['lastActivityAt'] != null
            ? DateTime.tryParse(json['lastActivityAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'totalProjects': totalProjects,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'lastActivityAt': lastActivityAt?.toIso8601String(),
      };
}

class TeamModel {
  final String id;
  final String tenantId;
  final String? workspaceId;
  final String name;
  final String? slug;
  final String? description;
  final String? avatar;
  final String createdBy;
  final String? industry;
  // size: 1-10 | 11-50 | 51-100 | 101-500 | 500+
  final String? size;
  // type: company | agency | startup | non-profit | educational | personal
  final String type;
  // status: active | archived | suspended
  final String status;
  final bool isActive;
  final List<TeamMember> members;
  final List<TeamInvite> invites;
  final int memberLimit;
  final List<String> projects;
  final TeamSettings settings;
  final TeamStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamModel({
    required this.id,
    required this.tenantId,
    this.workspaceId,
    required this.name,
    this.slug,
    this.description,
    this.avatar,
    required this.createdBy,
    this.industry,
    this.size,
    this.type = 'company',
    this.status = 'active',
    this.isActive = true,
    this.members = const [],
    this.invites = const [],
    this.memberLimit = 50,
    this.projects = const [],
    this.settings = const TeamSettings(),
    this.stats = const TeamStats(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] is Map
            ? json['tenantId']['_id'] ?? ''
            : json['tenantId'] ?? '',
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id']
            : json['workspaceId'],
        name: json['name'] ?? '',
        slug: json['slug'],
        description: json['description'],
        avatar: json['avatar'],
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id'] ?? ''
            : json['createdBy'] ?? '',
        industry: json['industry'],
        size: json['size'],
        type: json['type'] ?? 'company',
        status: json['status'] ?? 'active',
        isActive: json['isActive'] ?? true,
        members: (json['members'] as List? ?? [])
            .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        invites: (json['invites'] as List? ?? [])
            .map((i) => TeamInvite.fromJson(i as Map<String, dynamic>))
            .toList(),
        memberLimit: json['memberLimit'] ?? 50,
        projects: (json['projects'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        settings: json['settings'] != null
            ? TeamSettings.fromJson(json['settings'])
            : const TeamSettings(),
        stats: json['stats'] != null
            ? TeamStats.fromJson(json['stats'])
            : const TeamStats(),
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'workspaceId': workspaceId,
        'name': name,
        'slug': slug,
        'description': description,
        'avatar': avatar,
        'createdBy': createdBy,
        'industry': industry,
        'size': size,
        'type': type,
        'status': status,
        'isActive': isActive,
        'members': members.map((m) => m.toJson()).toList(),
        'invites': invites.map((i) => i.toJson()).toList(),
        'memberLimit': memberLimit,
        'projects': projects,
        'settings': settings.toJson(),
        'stats': stats.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
