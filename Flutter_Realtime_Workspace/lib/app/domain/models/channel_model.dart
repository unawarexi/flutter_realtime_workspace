class ChannelMember {
  final String userId;
  // role: admin | moderator | member
  final String role;
  final DateTime joinedAt;
  final DateTime? lastRead;
  final bool muted;
  // notificationPreference: all | mentions | none
  final String notificationPreference;

  const ChannelMember({
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.lastRead,
    this.muted = false,
    this.notificationPreference = 'all',
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) => ChannelMember(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        role: json['role'] ?? 'member',
        joinedAt:
            DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
        lastRead: json['lastRead'] != null
            ? DateTime.tryParse(json['lastRead'])
            : null,
        muted: json['muted'] ?? false,
        notificationPreference: json['notificationPreference'] ?? 'all',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
        'lastRead': lastRead?.toIso8601String(),
        'muted': muted,
        'notificationPreference': notificationPreference,
      };
}

class ChannelSettings {
  final bool allowThreads;
  final bool allowReactions;
  final bool allowFileUploads;
  final bool slowMode;
  final int? retentionDays;

  const ChannelSettings({
    this.allowThreads = true,
    this.allowReactions = true,
    this.allowFileUploads = true,
    this.slowMode = false,
    this.retentionDays,
  });

  factory ChannelSettings.fromJson(Map<String, dynamic> json) =>
      ChannelSettings(
        allowThreads: json['allowThreads'] ?? true,
        allowReactions: json['allowReactions'] ?? true,
        allowFileUploads: json['allowFileUploads'] ?? true,
        slowMode: json['slowMode'] ?? false,
        retentionDays: json['retentionDays'],
      );

  Map<String, dynamic> toJson() => {
        'allowThreads': allowThreads,
        'allowReactions': allowReactions,
        'allowFileUploads': allowFileUploads,
        'slowMode': slowMode,
        'retentionDays': retentionDays,
      };
}

class ChannelModel {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String tenantId;
  final String? orgId;
  final String workspaceId;
  // type: public | private | direct | group_dm
  final String type;
  final String? topic;
  final String? icon;
  final List<ChannelMember> members;
  final String? createdBy;
  final List<String> pinnedMessages;
  final ChannelSettings settings;
  // status: active | archived | deleted
  final String status;
  final DateTime? archivedAt;
  final int messageCount;
  final int memberCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChannelModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    required this.tenantId,
    this.orgId,
    required this.workspaceId,
    this.type = 'public',
    this.topic,
    this.icon,
    this.members = const [],
    this.createdBy,
    this.pinnedMessages = const [],
    this.settings = const ChannelSettings(),
    this.status = 'active',
    this.archivedAt,
    this.messageCount = 0,
    this.memberCount = 0,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) => ChannelModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'],
        description: json['description'],
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map
            ? json['orgId']['_id']
            : json['orgId'],
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id'] ?? ''
            : json['workspaceId'] ?? '',
        type: json['type'] ?? 'public',
        topic: json['topic'],
        icon: json['icon'],
        members: (json['members'] as List? ?? [])
            .map((m) => ChannelMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id']
            : json['createdBy'],
        pinnedMessages: (json['pinnedMessages'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        settings: json['settings'] != null
            ? ChannelSettings.fromJson(json['settings'])
            : const ChannelSettings(),
        status: json['status'] ?? 'active',
        archivedAt: json['archivedAt'] != null
            ? DateTime.tryParse(json['archivedAt'])
            : null,
        messageCount: json['messageCount'] ?? 0,
        memberCount: json['memberCount'] ?? 0,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.tryParse(json['lastMessageAt'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'tenantId': tenantId,
        'orgId': orgId,
        'workspaceId': workspaceId,
        'type': type,
        'topic': topic,
        'icon': icon,
        'members': members.map((m) => m.toJson()).toList(),
        'createdBy': createdBy,
        'pinnedMessages': pinnedMessages,
        'settings': settings.toJson(),
        'status': status,
        'archivedAt': archivedAt?.toIso8601String(),
        'messageCount': messageCount,
        'memberCount': memberCount,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
