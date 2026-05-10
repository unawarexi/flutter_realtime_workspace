class IssueComment {
  final String userId;
  final String content;
  final DateTime createdAt;

  const IssueComment({
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory IssueComment.fromJson(Map<String, dynamic> json) => IssueComment(
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

class IssueAttachment {
  final String url;
  final String? filename;
  final int? bytes;

  const IssueAttachment({required this.url, this.filename, this.bytes});

  factory IssueAttachment.fromJson(Map<String, dynamic> json) =>
      IssueAttachment(
        url: json['url'] ?? '',
        filename: json['filename'],
        bytes: json['bytes'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'filename': filename,
        'bytes': bytes,
      };
}

class LinkedIssue {
  // relation: blocks | blocked_by | duplicates | related_to
  final String issueId;
  final String relation;

  const LinkedIssue({required this.issueId, required this.relation});

  factory LinkedIssue.fromJson(Map<String, dynamic> json) => LinkedIssue(
        issueId: json['issueId'] is Map
            ? json['issueId']['_id'] ?? ''
            : json['issueId'] ?? '',
        relation: json['relation'] ?? 'related_to',
      );

  Map<String, dynamic> toJson() => {'issueId': issueId, 'relation': relation};
}

class IssueModel {
  final String id;
  final String tenantId;
  final String workspaceId;
  final String title;
  final String? description;
  final String? key;
  final String projectId;
  final String createdBy;
  final String? assignedTo; // was assigneeId
  final String? reporter;
  // priority: lowest | low | medium | high | critical
  final String priority;
  // status: open | in_progress | resolved | closed | reopened | wont_fix
  final String status;
  // type: bug | feature | improvement | task | epic | story
  final String type;
  // severity: trivial | minor | major | blocker
  final String severity;
  final List<String> tags;
  final List<String> labels;
  final List<IssueComment> comments;
  final List<IssueAttachment> attachments;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? environment;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final List<LinkedIssue> linkedIssues;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IssueModel({
    required this.id,
    required this.tenantId,
    required this.workspaceId,
    required this.title,
    this.description,
    this.key,
    required this.projectId,
    required this.createdBy,
    this.assignedTo,
    this.reporter,
    this.priority = 'medium',
    this.status = 'open',
    this.type = 'bug',
    this.severity = 'minor',
    this.tags = const [],
    this.labels = const [],
    this.comments = const [],
    this.attachments = const [],
    this.dueDate,
    this.resolvedAt,
    this.closedAt,
    this.environment,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.linkedIssues = const [],
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) => IssueModel(
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
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id'] ?? ''
            : json['createdBy'] ?? '',
        assignedTo: json['assignedTo'] is Map
            ? json['assignedTo']['_id']
            : json['assignedTo'],
        reporter: json['reporter'] is Map
            ? json['reporter']['_id']
            : json['reporter'],
        priority: json['priority'] ?? 'medium',
        status: json['status'] ?? 'open',
        type: json['type'] ?? 'bug',
        severity: json['severity'] ?? 'minor',
        tags: List<String>.from(json['tags'] ?? []),
        labels: List<String>.from(json['labels'] ?? []),
        comments: (json['comments'] as List? ?? [])
            .map((c) => IssueComment.fromJson(c as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List? ?? [])
            .map((a) => IssueAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'])
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'])
            : null,
        closedAt: json['closedAt'] != null
            ? DateTime.tryParse(json['closedAt'])
            : null,
        environment: json['environment'],
        stepsToReproduce: json['stepsToReproduce'],
        expectedBehavior: json['expectedBehavior'],
        actualBehavior: json['actualBehavior'],
        linkedIssues: (json['linkedIssues'] as List? ?? [])
            .map((l) => LinkedIssue.fromJson(l as Map<String, dynamic>))
            .toList(),
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
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'reporter': reporter,
        'priority': priority,
        'status': status,
        'type': type,
        'severity': severity,
        'tags': tags,
        'labels': labels,
        'comments': comments.map((c) => c.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'dueDate': dueDate?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'environment': environment,
        'stepsToReproduce': stepsToReproduce,
        'expectedBehavior': expectedBehavior,
        'actualBehavior': actualBehavior,
        'linkedIssues': linkedIssues.map((l) => l.toJson()).toList(),
        'deletedAt': deletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
