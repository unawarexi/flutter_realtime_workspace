class WorkflowSchedule {
  final String? cron;
  final String? timezone;

  const WorkflowSchedule({this.cron, this.timezone});

  factory WorkflowSchedule.fromJson(Map<String, dynamic> json) =>
      WorkflowSchedule(cron: json['cron'], timezone: json['timezone']);

  Map<String, dynamic> toJson() => {'cron': cron, 'timezone': timezone};
}

class WorkflowTrigger {
  // type: event | schedule | webhook | manual
  final String type;
  final String? event;
  final WorkflowSchedule? schedule;
  final String? webhookUrl;

  const WorkflowTrigger({
    required this.type,
    this.event,
    this.schedule,
    this.webhookUrl,
  });

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) =>
      WorkflowTrigger(
        type: json['type'] ?? 'manual',
        event: json['event'],
        schedule: json['schedule'] != null
            ? WorkflowSchedule.fromJson(json['schedule'])
            : null,
        webhookUrl: json['webhookUrl'],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'event': event,
        'schedule': schedule?.toJson(),
        'webhookUrl': webhookUrl,
      };
}

class WorkflowCondition {
  final String field;
  // operator: equals | not_equals | contains | gt | lt | in | not_in | exists
  final String operator;
  final dynamic value;

  const WorkflowCondition({
    required this.field,
    required this.operator,
    this.value,
  });

  factory WorkflowCondition.fromJson(Map<String, dynamic> json) =>
      WorkflowCondition(
        field: json['field'] ?? '',
        operator: json['operator'] ?? 'equals',
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
      };
}

class WorkflowAction {
  // type: send_notification | send_email | update_field | create_task | assign_user
  //       add_comment | trigger_webhook | ai_summarize | move_to_status | add_tag | remove_tag
  final String type;
  final Map<String, dynamic>? config;
  final int order;

  const WorkflowAction({
    required this.type,
    this.config,
    this.order = 0,
  });

  factory WorkflowAction.fromJson(Map<String, dynamic> json) => WorkflowAction(
        type: json['type'] ?? '',
        config: json['config'] as Map<String, dynamic>?,
        order: json['order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'config': config,
        'order': order,
      };
}

class WorkflowModel {
  final String id;
  final String name;
  final String? description;
  final String tenantId;
  final String? orgId;
  final String? workspaceId;
  final String createdBy;
  final WorkflowTrigger? trigger;
  final List<WorkflowCondition> conditions;
  final List<WorkflowAction> actions;
  final bool enabled; // was isActive
  final int executionCount;
  final DateTime? lastExecutedAt;
  final String? lastError;
  // status: active | paused | error | deleted
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkflowModel({
    required this.id,
    required this.name,
    this.description,
    required this.tenantId,
    this.orgId,
    this.workspaceId,
    required this.createdBy,
    this.trigger,
    this.conditions = const [],
    this.actions = const [],
    this.enabled = true,
    this.executionCount = 0,
    this.lastExecutedAt,
    this.lastError,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) => WorkflowModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id']
            : json['workspaceId'],
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id'] ?? ''
            : json['createdBy'] ?? '',
        trigger: json['trigger'] != null
            ? WorkflowTrigger.fromJson(json['trigger'])
            : null,
        conditions: (json['conditions'] as List? ?? [])
            .map((c) =>
                WorkflowCondition.fromJson(c as Map<String, dynamic>))
            .toList(),
        actions: (json['actions'] as List? ?? [])
            .map((a) => WorkflowAction.fromJson(a as Map<String, dynamic>))
            .toList(),
        enabled: json['enabled'] ?? true,
        executionCount: json['executionCount'] ?? 0,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.tryParse(json['lastExecutedAt'])
            : null,
        lastError: json['lastError'],
        status: json['status'] ?? 'active',
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'tenantId': tenantId,
        'orgId': orgId,
        'workspaceId': workspaceId,
        'createdBy': createdBy,
        'trigger': trigger?.toJson(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'enabled': enabled,
        'executionCount': executionCount,
        'lastExecutedAt': lastExecutedAt?.toIso8601String(),
        'lastError': lastError,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
