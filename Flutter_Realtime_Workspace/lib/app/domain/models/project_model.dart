class ProjectAttachment {
  final String url;
  final String? publicId;
  final String? resourceType;
  final String? format;
  final int? bytes;
  final String? filename;
  final String? originalFilename;
  final String? type;
  final int? width;
  final int? height;
  final double? duration;
  final DateTime? uploadedAt;
  final String? uploadedBy;

  const ProjectAttachment({
    required this.url,
    this.publicId,
    this.resourceType,
    this.format,
    this.bytes,
    this.filename,
    this.originalFilename,
    this.type,
    this.width,
    this.height,
    this.duration,
    this.uploadedAt,
    this.uploadedBy,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) =>
      ProjectAttachment(
        url: json['url'] ?? '',
        publicId: json['public_id'] ?? json['publicId'],
        resourceType: json['resource_type'] ?? json['resourceType'],
        format: json['format'],
        bytes: json['bytes'],
        filename: json['filename'],
        originalFilename: json['original_filename'] ?? json['originalFilename'],
        type: json['type'],
        width: json['width'],
        height: json['height'],
        duration: (json['duration'] as num?)?.toDouble(),
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'])
            : null,
        uploadedBy: json['uploadedBy'] is Map
            ? json['uploadedBy']['_id']
            : json['uploadedBy'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'public_id': publicId,
        'resource_type': resourceType,
        'format': format,
        'bytes': bytes,
        'filename': filename,
        'original_filename': originalFilename,
        'type': type,
        'width': width,
        'height': height,
        'duration': duration,
        'uploadedAt': uploadedAt?.toIso8601String(),
        'uploadedBy': uploadedBy,
      };
}

class ProjectTimelineEvent {
  final String title;
  final String? description;
  final DateTime date;
  final String? type;

  const ProjectTimelineEvent({
    required this.title,
    this.description,
    required this.date,
    this.type,
  });

  factory ProjectTimelineEvent.fromJson(Map<String, dynamic> json) =>
      ProjectTimelineEvent(
        title: json['title'] ?? '',
        description: json['description'],
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'type': type,
      };
}

class ProjectBudget {
  final double? allocated;
  final double? spent;
  final String currency;

  const ProjectBudget({
    this.allocated,
    this.spent,
    this.currency = 'USD',
  });

  factory ProjectBudget.fromJson(Map<String, dynamic> json) => ProjectBudget(
        allocated: (json['allocated'] as num?)?.toDouble(),
        spent: (json['spent'] as num?)?.toDouble(),
        currency: json['currency'] ?? 'USD',
      );

  Map<String, dynamic> toJson() => {
        'allocated': allocated,
        'spent': spent,
        'currency': currency,
      };
}

class ProjectTimeTracking {
  final double? estimated;
  final double? actual;
  final String unit; // hours

  const ProjectTimeTracking({
    this.estimated,
    this.actual,
    this.unit = 'hours',
  });

  factory ProjectTimeTracking.fromJson(Map<String, dynamic> json) =>
      ProjectTimeTracking(
        estimated: (json['estimated'] as num?)?.toDouble(),
        actual: (json['actual'] as num?)?.toDouble(),
        unit: json['unit'] ?? 'hours',
      );

  Map<String, dynamic> toJson() => {
        'estimated': estimated,
        'actual': actual,
        'unit': unit,
      };
}

class ProjectSettings {
  final bool isPublic;
  final bool allowComments;
  final bool notifications;
  final bool autoArchive;
  final int autoArchiveDays;

  const ProjectSettings({
    this.isPublic = false,
    this.allowComments = true,
    this.notifications = true,
    this.autoArchive = false,
    this.autoArchiveDays = 30,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      ProjectSettings(
        isPublic: json['isPublic'] ?? false,
        allowComments: json['allowComments'] ?? true,
        notifications: json['notifications'] ?? true,
        autoArchive: json['autoArchive'] ?? false,
        autoArchiveDays: json['autoArchiveDays'] ?? 30,
      );

  Map<String, dynamic> toJson() => {
        'isPublic': isPublic,
        'allowComments': allowComments,
        'notifications': notifications,
        'autoArchive': autoArchive,
        'autoArchiveDays': autoArchiveDays,
      };
}

class ProjectModel {
  final String id;
  final String tenantId; // ObjectId ref -> String (Organization)
  final String workspaceId;
  final String name;
  final String? key;
  final String? description;
  // template: Kanban | Scrum | Blank Project | Project Management | Task Tracking
  final String? template;
  // status: active | archived | on-hold | completed | planning | review | cancelled
  final String status;
  // priority: low | medium | high | critical
  final String priority;
  final String? color;
  final bool isActive;
  final bool archived;
  final bool completed;
  final bool recent;
  final bool starred;
  final String? teamId;
  final String createdBy;
  final List<String> collaborators;
  final List<String> members;
  final List<String> tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? lastViewed;
  final double progress; // 0 to 1
  final List<ProjectAttachment> attachments;
  final List<ProjectTimelineEvent> timeline;
  final ProjectBudget? budget;
  final ProjectTimeTracking? timeTracking;
  final ProjectSettings settings;
  final Map<String, dynamic>? customFields;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.tenantId,
    required this.workspaceId,
    required this.name,
    this.key,
    this.description,
    this.template,
    this.status = 'active',
    this.priority = 'medium',
    this.color,
    this.isActive = true,
    this.archived = false,
    this.completed = false,
    this.recent = false,
    this.starred = false,
    this.teamId,
    required this.createdBy,
    this.collaborators = const [],
    this.members = const [],
    this.tags = const [],
    this.startDate,
    this.endDate,
    this.lastViewed,
    this.progress = 0,
    this.attachments = const [],
    this.timeline = const [],
    this.budget,
    this.timeTracking,
    this.settings = const ProjectSettings(),
    this.customFields,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] is Map
            ? json['tenantId']['_id'] ?? ''
            : json['tenantId'] ?? '',
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id'] ?? ''
            : json['workspaceId'] ?? '',
        name: json['name'] ?? '',
        key: json['key'],
        description: json['description'],
        template: json['template'],
        status: json['status'] ?? 'active',
        priority: json['priority'] ?? 'medium',
        color: json['color'],
        isActive: json['isActive'] ?? true,
        archived: json['archived'] ?? false,
        completed: json['completed'] ?? false,
        recent: json['recent'] ?? false,
        starred: json['starred'] ?? false,
        teamId: json['teamId'] is Map
            ? json['teamId']['_id']
            : json['teamId'],
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id'] ?? ''
            : json['createdBy'] ?? '',
        collaborators: (json['collaborators'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        members: (json['members'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        tags: List<String>.from(json['tags'] ?? []),
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'])
            : null,
        endDate: json['endDate'] != null
            ? DateTime.tryParse(json['endDate'])
            : null,
        lastViewed: json['lastViewed'] != null
            ? DateTime.tryParse(json['lastViewed'])
            : null,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        attachments: (json['attachments'] as List? ?? [])
            .map((a) =>
                ProjectAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        timeline: (json['timeline'] as List? ?? [])
            .map((t) =>
                ProjectTimelineEvent.fromJson(t as Map<String, dynamic>))
            .toList(),
        budget: json['budget'] != null
            ? ProjectBudget.fromJson(json['budget'])
            : null,
        timeTracking: json['timeTracking'] != null
            ? ProjectTimeTracking.fromJson(json['timeTracking'])
            : null,
        settings: json['settings'] != null
            ? ProjectSettings.fromJson(json['settings'])
            : const ProjectSettings(),
        customFields: json['customFields'] as Map<String, dynamic>?,
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'])
            : null,
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
        'key': key,
        'description': description,
        'template': template,
        'status': status,
        'priority': priority,
        'color': color,
        'isActive': isActive,
        'archived': archived,
        'completed': completed,
        'recent': recent,
        'starred': starred,
        'teamId': teamId,
        'createdBy': createdBy,
        'collaborators': collaborators,
        'members': members,
        'tags': tags,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'lastViewed': lastViewed?.toIso8601String(),
        'progress': progress,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'budget': budget?.toJson(),
        'timeTracking': timeTracking?.toJson(),
        'settings': settings.toJson(),
        'customFields': customFields,
        'deletedAt': deletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
