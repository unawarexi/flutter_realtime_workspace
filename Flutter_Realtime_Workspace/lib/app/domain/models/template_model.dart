class TemplateVariable {
  final String name;
  final String? description;
  final bool required;

  const TemplateVariable({
    required this.name,
    this.description,
    this.required = false,
  });

  factory TemplateVariable.fromJson(Map<String, dynamic> json) =>
      TemplateVariable(
        name: json['name'] ?? '',
        description: json['description'],
        required: json['required'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'required': required,
      };
}

class TemplateModel {
  final String id;
  final String name;
  final String? slug;
  final String? tenantId;
  final String? orgId;
  // type: email | pdf | notification | invoice
  final String type;
  final String? subject;
  final String body;
  final List<TemplateVariable> variables;
  final String? category;
  final bool isDefault;
  final int version;
  // status: active | draft | archived
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateModel({
    required this.id,
    required this.name,
    this.slug,
    this.tenantId,
    this.orgId,
    required this.type,
    this.subject,
    required this.body,
    this.variables = const [],
    this.category,
    this.isDefault = false,
    this.version = 1,
    this.status = 'active',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'],
        tenantId: json['tenantId'],
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        type: json['type'] ?? 'email',
        subject: json['subject'],
        body: json['body'] ?? '',
        variables: (json['variables'] as List? ?? [])
            .map((v) => TemplateVariable.fromJson(v as Map<String, dynamic>))
            .toList(),
        category: json['category'],
        isDefault: json['isDefault'] ?? false,
        version: json['version'] ?? 1,
        status: json['status'] ?? 'active',
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id']
            : json['createdBy'],
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
        'type': type,
        'subject': subject,
        'body': body,
        'variables': variables.map((v) => v.toJson()).toList(),
        'category': category,
        'isDefault': isDefault,
        'version': version,
        'status': status,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
