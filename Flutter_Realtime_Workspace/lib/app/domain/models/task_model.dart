class TaskChecklistItem {
  final String title;
  final bool completed;

  const TaskChecklistItem({required this.title, this.completed = false});

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) =>
      TaskChecklistItem(
        title: json['title'] ?? '',
        completed: json['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {'title': title, 'completed': completed};
}

class TaskComment {
  final String userId;
  final String content;
  final DateTime createdAt;

  const TaskComment({
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        content: json['content'] ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TaskAttachment {
  final String url;
  final String? filename;
  final int? bytes;
  final DateTime? uploadedAt;

  const TaskAttachment({
    required this.url,
    this.filename,
    this.bytes,
    this.uploadedAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        url: json['url'] ?? '',
        filename: json['filename'],
        bytes: json['bytes'],
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'filename': filename,
        'bytes': bytes,
        'uploadedAt': uploadedAt?.toIso8601String(),
      };
}

class TaskModel {
  final String id;
  final String tenantId;
  final String workspaceId;
  final String title;
  final String? description;
  final String? key;
  final String projectId;
  final String? issueId;
  final String? parentTaskId;
  final String? assignedTo; // ObjectId ref -> String (was assigneeId)
  final String createdBy;
  final List<String> watchers;
  // status: backlog | todo | in_progress | in_review | done | blocked | cancelled
  final String status;
  // priority: lowest | low | medium | high | critical
  final String priority;
  final List<String> labels; // plain strings, not IDs
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? completedAt;
  final double? estimatedHours;
  final double loggedHours;
  final List<TaskChecklistItem> checklist;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final int sortOrder; // was "position"
  final String? sprintId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.tenantId,
    required this.workspaceId,
    required this.title,
    this.description,
    this.key,
    required this.projectId,
    this.issueId,
    this.parentTaskId,
    this.assignedTo,
    required this.createdBy,
    this.watchers = const [],
    this.status = 'todo',
    this.priority = 'medium',
    this.labels = const [],
    this.dueDate,
    this.startDate,
    this.completedAt,
    this.estimatedHours,
    this.loggedHours = 0,
    this.checklist = const [],
    this.comments = const [],
    this.attachments = const [],
    this.sortOrder = 0,
    this.sprintId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] is Map
            ? json['tenantId']['_id'] ?? ''
            : json['tenantId'] ?? '',
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id'] ?? ''
            : json['workspaceId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        key: json['key'],
        projectId: json['projectId'] is Map
            ? json['projectId']['_id'] ?? ''
            : json['projectId'] ?? '',
        issueId: json['issueId'] is Map
            ? json['issueId']['_id']
            : json['issueId'],
        parentTaskId: json['parentTaskId'] is Map
            ? json['parentTaskId']['_id']
            : json['parentTaskId'],
        assignedTo: json['assignedTo'] is Map
            ? json['assignedTo']['_id']
            : json['assignedTo'],
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id'] ?? ''
            : json['createdBy'] ?? '',
        watchers: (json['watchers'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        status: json['status'] ?? 'todo',
        priority: json['priority'] ?? 'medium',
        labels: List<String>.from(json['labels'] ?? []),
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'])
            : null,
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'])
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'])
            : null,
        estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
        loggedHours: (json['loggedHours'] as num?)?.toDouble() ?? 0,
        checklist: (json['checklist'] as List? ?? [])
            .map((c) =>
                TaskChecklistItem.fromJson(c as Map<String, dynamic>))
            .toList(),
        comments: (json['comments'] as List? ?? [])
            .map((c) => TaskComment.fromJson(c as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List? ?? [])
            .map((a) => TaskAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        sortOrder: json['sortOrder'] ?? 0,
        sprintId: json['sprintId'] is Map
            ? json['sprintId']['_id']
            : json['sprintId'],
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
        'title': title,
        'description': description,
        'key': key,
        'projectId': projectId,
        'issueId': issueId,
        'parentTaskId': parentTaskId,
        'assignedTo': assignedTo,
        'createdBy': createdBy,
        'watchers': watchers,
        'status': status,
        'priority': priority,
        'labels': labels,
        'dueDate': dueDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'estimatedHours': estimatedHours,
        'loggedHours': loggedHours,
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'sortOrder': sortOrder,
        'sprintId': sprintId,
        'deletedAt': deletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
