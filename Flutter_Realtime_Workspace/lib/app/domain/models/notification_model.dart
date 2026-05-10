class NotificationResource {
  final String? type;
  final String? id;
  final String? name;

  const NotificationResource({this.type, this.id, this.name});

  factory NotificationResource.fromJson(Map<String, dynamic> json) =>
      NotificationResource(
          type: json['type'], id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'type': type, 'id': id, 'name': name};
}

class NotificationModel {
  final String id;
  final String tenantId;
  final String recipientId; // was userId/receiverId
  final String? senderId;
  // type: mention | assignment | comment | invite | meeting | task_update |
  //       project_update | ticket_update | system | ai_result | workflow
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  // channel: in_app | email | push | sms
  final String channel;
  final NotificationResource? resource;
  final bool read;
  final DateTime? readAt;
  final String? actionUrl;
  // priority: low | normal | high | urgent
  final String priority;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.tenantId,
    required this.recipientId,
    this.senderId,
    required this.type,
    required this.title,
    this.body,
    this.data,
    this.channel = 'in_app',
    this.resource,
    this.read = false,
    this.readAt,
    this.actionUrl,
    this.priority = 'normal',
    this.expiresAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        recipientId: json['recipientId'] is Map
            ? json['recipientId']['_id'] ?? ''
            : json['recipientId'] ?? '',
        senderId: json['senderId'] is Map
            ? json['senderId']['_id']
            : json['senderId'],
        type: json['type'] ?? 'system',
        title: json['title'] ?? '',
        body: json['body'],
        data: json['data'] as Map<String, dynamic>?,
        channel: json['channel'] ?? 'in_app',
        resource: json['resource'] != null
            ? NotificationResource.fromJson(
                json['resource'] as Map<String, dynamic>)
            : null,
        read: json['read'] ?? false,
        readAt: json['readAt'] != null
            ? DateTime.tryParse(json['readAt'])
            : null,
        actionUrl: json['actionUrl'],
        priority: json['priority'] ?? 'normal',
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'recipientId': recipientId,
        'senderId': senderId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'channel': channel,
        'resource': resource?.toJson(),
        'read': read,
        'readAt': readAt?.toIso8601String(),
        'actionUrl': actionUrl,
        'priority': priority,
        'expiresAt': expiresAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        tenantId: tenantId,
        recipientId: recipientId,
        senderId: senderId,
        type: type,
        title: title,
        body: body,
        data: data,
        channel: channel,
        resource: resource,
        read: read ?? this.read,
        readAt: readAt,
        actionUrl: actionUrl,
        priority: priority,
        expiresAt: expiresAt,
        createdAt: createdAt,
      );
}

class NotificationChannelPrefs {
  final bool email;
  final bool push;
  final bool sms;
  final bool inApp;

  const NotificationChannelPrefs({
    this.email = true,
    this.push = true,
    this.sms = false,
    this.inApp = true,
  });

  factory NotificationChannelPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationChannelPrefs(
        email: json['email'] ?? true,
        push: json['push'] ?? true,
        sms: json['sms'] ?? false,
        inApp: json['inApp'] ?? true,
      );

  Map<String, dynamic> toJson() =>
      {'email': email, 'push': push, 'sms': sms, 'inApp': inApp};
}

class QuietHours {
  final bool enabled;
  final String? start;
  final String? end;
  final String? timezone;

  const QuietHours({
    this.enabled = false,
    this.start,
    this.end,
    this.timezone,
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
        enabled: json['enabled'] ?? false,
        start: json['start'],
        end: json['end'],
        timezone: json['timezone'],
      );

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'start': start, 'end': end, 'timezone': timezone};
}

class NotificationPreferenceModel {
  final String id;
  final String userId;
  final String tenantId;
  final NotificationChannelPrefs channels;
  // digestFrequency: realtime | hourly | daily | weekly
  final String digestFrequency;
  final QuietHours? quietHours;
  final List<String> mutedChannels;
  final List<String> mutedProjects;
  final Map<String, dynamic>? typeOverrides;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    required this.tenantId,
    this.channels = const NotificationChannelPrefs(),
    this.digestFrequency = 'realtime',
    this.quietHours,
    this.mutedChannels = const [],
    this.mutedProjects = const [],
    this.typeOverrides,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) =>
      NotificationPreferenceModel(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        tenantId: json['tenantId'] ?? '',
        channels: json['channels'] != null
            ? NotificationChannelPrefs.fromJson(json['channels'])
            : const NotificationChannelPrefs(),
        digestFrequency: json['digestFrequency'] ?? 'realtime',
        quietHours: json['quietHours'] != null
            ? QuietHours.fromJson(json['quietHours'])
            : null,
        mutedChannels: List<String>.from(json['mutedChannels'] ?? []),
        mutedProjects: List<String>.from(json['mutedProjects'] ?? []),
        typeOverrides: json['typeOverrides'] as Map<String, dynamic>?,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'tenantId': tenantId,
        'channels': channels.toJson(),
        'digestFrequency': digestFrequency,
        'quietHours': quietHours?.toJson(),
        'mutedChannels': mutedChannels,
        'mutedProjects': mutedProjects,
        'typeOverrides': typeOverrides,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
