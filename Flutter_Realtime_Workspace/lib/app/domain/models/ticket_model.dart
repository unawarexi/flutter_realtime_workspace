class UserInfo {
  final String id;
  final String? email;
  final String? fullName;
  final String? profilePicture;

  const UserInfo({
    required this.id,
    this.email,
    this.fullName,
    this.profilePicture,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['_id'] ?? json['id'] ?? '',
        email: json['email'],
        fullName: json['fullName'],
        profilePicture: json['profilePicture'],
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'fullName': fullName,
        'profilePicture': profilePicture,
      };
}

class TicketComment {
  final String userId;
  final String content;
  final bool internal; // internal note visible only to staff
  final DateTime createdAt;

  const TicketComment({
    required this.userId,
    required this.content,
    this.internal = false,
    required this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) => TicketComment(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        content: json['content'] ?? '',
        internal: json['internal'] ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'content': content,
        'internal': internal,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TicketAttachment {
  final String url;
  final String? publicId;
  final String? filename;
  final String? mimeType;
  final int? bytes;

  const TicketAttachment({
    required this.url,
    this.publicId,
    this.filename,
    this.mimeType,
    this.bytes,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      TicketAttachment(
        url: json['url'] ?? '',
        publicId: json['publicId'],
        filename: json['filename'],
        mimeType: json['mimeType'],
        bytes: json['bytes'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'publicId': publicId,
        'filename': filename,
        'mimeType': mimeType,
        'bytes': bytes,
      };
}

class TicketRelatedTo {
  final String? type; // project | task | issue
  final String? id;

  const TicketRelatedTo({this.type, this.id});

  factory TicketRelatedTo.fromJson(Map<String, dynamic> json) =>
      TicketRelatedTo(type: json['type'], id: json['id']);

  Map<String, dynamic> toJson() => {'type': type, 'id': id};
}

class TicketSla {
  final DateTime? responseDeadline;
  final DateTime? resolutionDeadline;
  final bool breached;

  const TicketSla({
    this.responseDeadline,
    this.resolutionDeadline,
    this.breached = false,
  });

  factory TicketSla.fromJson(Map<String, dynamic> json) => TicketSla(
        responseDeadline: json['responseDeadline'] != null
            ? DateTime.tryParse(json['responseDeadline'])
            : null,
        resolutionDeadline: json['resolutionDeadline'] != null
            ? DateTime.tryParse(json['resolutionDeadline'])
            : null,
        breached: json['breached'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'responseDeadline': responseDeadline?.toIso8601String(),
        'resolutionDeadline': resolutionDeadline?.toIso8601String(),
        'breached': breached,
      };
}

class TicketModel {
  final String id;
  final String title;
  final String? description;
  final String? ticketNumber;
  final String tenantId;
  final String? orgId;
  final String? workspaceId;
  // type: bug | feature | support | question | incident
  final String type;
  // priority: critical | high | medium | low
  final String priority;
  // status: open | in_progress | waiting | resolved | closed
  final String status;
  final String? category;
  final List<String> tags;
  final UserInfo reporter;
  final UserInfo? assignee;
  final List<String> watchers;
  final List<TicketComment> comments;
  final List<TicketAttachment> attachments;
  final TicketRelatedTo? relatedTo;
  final TicketSla? sla;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? firstResponseAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketModel({
    required this.id,
    required this.title,
    this.description,
    this.ticketNumber,
    required this.tenantId,
    this.orgId,
    this.workspaceId,
    this.type = 'support',
    this.priority = 'medium',
    this.status = 'open',
    this.category,
    this.tags = const [],
    required this.reporter,
    this.assignee,
    this.watchers = const [],
    this.comments = const [],
    this.attachments = const [],
    this.relatedTo,
    this.sla,
    this.resolvedAt,
    this.closedAt,
    this.firstResponseAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        ticketNumber: json['ticketNumber'],
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map
            ? json['orgId']['_id']
            : json['orgId'],
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id']
            : json['workspaceId'],
        type: json['type'] ?? 'support',
        priority: json['priority'] ?? 'medium',
        status: json['status'] ?? 'open',
        category: json['category'],
        tags: List<String>.from(json['tags'] ?? []),
        reporter: json['reporter'] != null
            ? UserInfo.fromJson(json['reporter'] as Map<String, dynamic>)
            : const UserInfo(id: ''),
        assignee: json['assignee'] != null
            ? UserInfo.fromJson(json['assignee'] as Map<String, dynamic>)
            : null,
        watchers: (json['watchers'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        comments: (json['comments'] as List? ?? [])
            .map((c) =>
                TicketComment.fromJson(c as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List? ?? [])
            .map((a) =>
                TicketAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        relatedTo: json['relatedTo'] != null
            ? TicketRelatedTo.fromJson(
                json['relatedTo'] as Map<String, dynamic>)
            : null,
        sla: json['sla'] != null
            ? TicketSla.fromJson(json['sla'] as Map<String, dynamic>)
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'])
            : null,
        closedAt: json['closedAt'] != null
            ? DateTime.tryParse(json['closedAt'])
            : null,
        firstResponseAt: json['firstResponseAt'] != null
            ? DateTime.tryParse(json['firstResponseAt'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'ticketNumber': ticketNumber,
        'tenantId': tenantId,
        'orgId': orgId,
        'workspaceId': workspaceId,
        'type': type,
        'priority': priority,
        'status': status,
        'category': category,
        'tags': tags,
        'reporter': reporter.toJson(),
        'assignee': assignee?.toJson(),
        'watchers': watchers,
        'comments': comments.map((c) => c.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'relatedTo': relatedTo?.toJson(),
        'sla': sla?.toJson(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'firstResponseAt': firstResponseAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
