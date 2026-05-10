class AuditActor {
  final String userId;
  final String? email;
  final String? role;
  final String? ip;
  final String? userAgent;

  const AuditActor({
    required this.userId,
    this.email,
    this.role,
    this.ip,
    this.userAgent,
  });

  factory AuditActor.fromJson(Map<String, dynamic> json) => AuditActor(
        userId: json['userId'] ?? '',
        email: json['email'],
        role: json['role'],
        ip: json['ip'],
        userAgent: json['userAgent'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'role': role,
        'ip': ip,
        'userAgent': userAgent,
      };
}

class AuditTarget {
  final String? type;
  final String? id;
  final String? name;

  const AuditTarget({this.type, this.id, this.name});

  factory AuditTarget.fromJson(Map<String, dynamic> json) => AuditTarget(
        type: json['type'],
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {'type': type, 'id': id, 'name': name};
}

class AuditChanges {
  final dynamic before;
  final dynamic after;

  const AuditChanges({this.before, this.after});

  factory AuditChanges.fromJson(Map<String, dynamic> json) =>
      AuditChanges(before: json['before'], after: json['after']);

  Map<String, dynamic> toJson() => {'before': before, 'after': after};
}

class AuditLogModel {
  final String id;
  final String tenantId;
  final String? orgId;
  final String action;
  // category: auth | iam | data | admin | ai | billing | system
  final String category;
  final AuditActor actor;
  final AuditTarget? target;
  final AuditChanges? changes;
  final Map<String, dynamic>? metadata;
  final String? requestId;
  final String? traceId;
  // status: success | failure
  final String status;
  final String? errorMessage;
  final DateTime createdAt; // append-only, no updatedAt

  const AuditLogModel({
    required this.id,
    required this.tenantId,
    this.orgId,
    required this.action,
    required this.category,
    required this.actor,
    this.target,
    this.changes,
    this.metadata,
    this.requestId,
    this.traceId,
    this.status = 'success',
    this.errorMessage,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        action: json['action'] ?? '',
        category: json['category'] ?? 'system',
        actor: json['actor'] != null
            ? AuditActor.fromJson(json['actor'] as Map<String, dynamic>)
            : AuditActor(userId: ''),
        target: json['target'] != null
            ? AuditTarget.fromJson(json['target'] as Map<String, dynamic>)
            : null,
        changes: json['changes'] != null
            ? AuditChanges.fromJson(json['changes'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
        requestId: json['requestId'],
        traceId: json['traceId'],
        status: json['status'] ?? 'success',
        errorMessage: json['errorMessage'],
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'orgId': orgId,
        'action': action,
        'category': category,
        'actor': actor.toJson(),
        'target': target?.toJson(),
        'changes': changes?.toJson(),
        'metadata': metadata,
        'requestId': requestId,
        'traceId': traceId,
        'status': status,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
      };
}
