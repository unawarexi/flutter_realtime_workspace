class RolePermission {
  final String resource;
  final List<String> actions;

  const RolePermission({required this.resource, this.actions = const []});

  factory RolePermission.fromJson(Map<String, dynamic> json) => RolePermission(
        resource: json['resource'] ?? '',
        actions: List<String>.from(json['actions'] ?? []),
      );

  Map<String, dynamic> toJson() => {'resource': resource, 'actions': actions};
}

class RoleModel {
  final String id;
  final String name;
  final String? slug;
  final String? tenantId;
  final String? orgId;
  final String? description;
  final List<RolePermission> permissions;
  final bool isSystem;
  final int hierarchy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoleModel({
    required this.id,
    required this.name,
    this.slug,
    this.tenantId,
    this.orgId,
    this.description,
    this.permissions = const [],
    this.isSystem = false,
    this.hierarchy = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'],
        tenantId: json['tenantId'],
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        description: json['description'],
        permissions: (json['permissions'] as List? ?? [])
            .map((p) => RolePermission.fromJson(p as Map<String, dynamic>))
            .toList(),
        isSystem: json['isSystem'] ?? false,
        hierarchy: json['hierarchy'] ?? 0,
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
        'description': description,
        'permissions': permissions.map((p) => p.toJson()).toList(),
        'isSystem': isSystem,
        'hierarchy': hierarchy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class PolicyCondition {
  final String attribute;
  final String operator;
  final dynamic value;

  const PolicyCondition({
    required this.attribute,
    required this.operator,
    this.value,
  });

  factory PolicyCondition.fromJson(Map<String, dynamic> json) =>
      PolicyCondition(
        attribute: json['attribute'] ?? '',
        operator: json['operator'] ?? '',
        value: json['value'],
      );

  Map<String, dynamic> toJson() =>
      {'attribute': attribute, 'operator': operator, 'value': value};
}

class PolicyModel {
  final String id;
  final String name;
  final String? tenantId;
  final String? orgId;
  final String? description;
  // effect: allow | deny
  final String effect;
  final List<PolicyCondition> conditions;
  final String? resource;
  final List<String> actions;
  final bool enabled;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PolicyModel({
    required this.id,
    required this.name,
    this.tenantId,
    this.orgId,
    this.description,
    this.effect = 'allow',
    this.conditions = const [],
    this.resource,
    this.actions = const [],
    this.enabled = true,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) => PolicyModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        tenantId: json['tenantId'],
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        description: json['description'],
        effect: json['effect'] ?? 'allow',
        conditions: (json['conditions'] as List? ?? [])
            .map((c) => PolicyCondition.fromJson(c as Map<String, dynamic>))
            .toList(),
        resource: json['resource'],
        actions: List<String>.from(json['actions'] ?? []),
        enabled: json['enabled'] ?? true,
        priority: json['priority'] ?? 0,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'tenantId': tenantId,
        'orgId': orgId,
        'description': description,
        'effect': effect,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'resource': resource,
        'actions': actions,
        'enabled': enabled,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
