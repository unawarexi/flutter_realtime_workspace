class IntegrationConfig {
  final String? webhookUrl;
  final String? apiKey;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final Map<String, String>? customHeaders;
  final List<String> scopes;

  const IntegrationConfig({
    this.webhookUrl,
    this.apiKey,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.customHeaders,
    this.scopes = const [],
  });

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) =>
      IntegrationConfig(
        webhookUrl: json['webhookUrl'],
        apiKey: json['apiKey'],
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        tokenExpiresAt: json['tokenExpiresAt'] != null
            ? DateTime.tryParse(json['tokenExpiresAt'])
            : null,
        customHeaders: json['customHeaders'] != null
            ? Map<String, String>.from(json['customHeaders'])
            : null,
        scopes: List<String>.from(json['scopes'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'webhookUrl': webhookUrl,
        'apiKey': apiKey,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
        'customHeaders': customHeaders,
        'scopes': scopes,
      };
}

class IntegrationModel {
  final String id;
  final String tenantId;
  final String orgId;
  final String name;
  // type: github | gitlab | slack | google_drive | onedrive | zoom | jira | notion | figma | custom_webhook
  final String type;
  final IntegrationConfig? config;
  final List<String> events;
  final bool enabled; // was isActive
  final DateTime? lastSyncAt;
  final String? lastError;
  // status: active | error | disabled
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IntegrationModel({
    required this.id,
    required this.tenantId,
    required this.orgId,
    required this.name,
    required this.type,
    this.config,
    this.events = const [],
    this.enabled = true,
    this.lastSyncAt,
    this.lastError,
    this.status = 'active',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntegrationModel.fromJson(Map<String, dynamic> json) =>
      IntegrationModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map
            ? json['orgId']['_id'] ?? ''
            : json['orgId'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        config: json['config'] != null
            ? IntegrationConfig.fromJson(json['config'])
            : null,
        events: List<String>.from(json['events'] ?? []),
        enabled: json['enabled'] ?? true,
        lastSyncAt: json['lastSyncAt'] != null
            ? DateTime.tryParse(json['lastSyncAt'])
            : null,
        lastError: json['lastError'],
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
        'tenantId': tenantId,
        'orgId': orgId,
        'name': name,
        'type': type,
        'config': config?.toJson(),
        'events': events,
        'enabled': enabled,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'lastError': lastError,
        'status': status,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
