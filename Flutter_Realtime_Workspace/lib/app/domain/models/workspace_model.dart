class WorkspaceMember {
  final String userId;
  final String role; // workspace_admin | manager | member | guest
  final DateTime joinedAt;

  const WorkspaceMember({
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) =>
      WorkspaceMember(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        role: json['role'] ?? 'member',
        joinedAt:
            DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
      };
}

class WorkspaceSettings {
  final String visibility; // public | private | invite_only
  final String defaultProjectTemplate; // kanban | scrum | blank
  final bool allowGuests;
  final bool notificationsEnabled;

  const WorkspaceSettings({
    this.visibility = 'private',
    this.defaultProjectTemplate = 'kanban',
    this.allowGuests = false,
    this.notificationsEnabled = true,
  });

  factory WorkspaceSettings.fromJson(Map<String, dynamic> json) =>
      WorkspaceSettings(
        visibility: json['visibility'] ?? 'private',
        defaultProjectTemplate: json['defaultProjectTemplate'] ?? 'kanban',
        allowGuests: json['allowGuests'] ?? false,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'visibility': visibility,
        'defaultProjectTemplate': defaultProjectTemplate,
        'allowGuests': allowGuests,
        'notificationsEnabled': notificationsEnabled,
      };
}

class WorkspaceModel {
  final String id;
  final String name;
  final String slug;
  final String tenantId;
  final String orgId;
  final String owner; // ObjectId ref -> String
  final String? description;
  final String? icon;
  final String color;
  final String? coverImage;
  final List<WorkspaceMember> members;
  final WorkspaceSettings settings;
  final String status; // active | archived | deleted
  final DateTime? archivedAt;
  final int projectCount;
  final int memberCount;
  final int channelCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.tenantId,
    required this.orgId,
    required this.owner,
    this.description,
    this.icon,
    this.color = '#6366F1',
    this.coverImage,
    this.members = const [],
    this.settings = const WorkspaceSettings(),
    this.status = 'active',
    this.archivedAt,
    this.projectCount = 0,
    this.memberCount = 0,
    this.channelCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map
            ? json['orgId']['_id'] ?? ''
            : json['orgId'] ?? '',
        owner: json['owner'] is Map
            ? json['owner']['_id'] ?? ''
            : json['owner'] ?? '',
        description: json['description'],
        icon: json['icon'],
        color: json['color'] ?? '#6366F1',
        coverImage: json['coverImage'],
        members: (json['members'] as List? ?? [])
            .map((m) => WorkspaceMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        settings: json['settings'] != null
            ? WorkspaceSettings.fromJson(json['settings'])
            : const WorkspaceSettings(),
        status: json['status'] ?? 'active',
        archivedAt: json['archivedAt'] != null
            ? DateTime.tryParse(json['archivedAt'])
            : null,
        projectCount: json['projectCount'] ?? 0,
        memberCount: json['memberCount'] ?? 0,
        channelCount: json['channelCount'] ?? 0,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'tenantId': tenantId,
        'orgId': orgId,
        'owner': owner,
        'description': description,
        'icon': icon,
        'color': color,
        'coverImage': coverImage,
        'members': members.map((m) => m.toJson()).toList(),
        'settings': settings.toJson(),
        'status': status,
        'archivedAt': archivedAt?.toIso8601String(),
        'projectCount': projectCount,
        'memberCount': memberCount,
        'channelCount': channelCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
