class OrgQuotas {
  final int maxMembers;
  final int maxWorkspaces;
  final int maxProjects;
  final int maxStorageGB;
  final int aiCredits;

  const OrgQuotas({
    this.maxMembers = 5,
    this.maxWorkspaces = 3,
    this.maxProjects = 10,
    this.maxStorageGB = 5,
    this.aiCredits = 100,
  });

  factory OrgQuotas.fromJson(Map<String, dynamic> json) => OrgQuotas(
        maxMembers: json['maxMembers'] ?? 5,
        maxWorkspaces: json['maxWorkspaces'] ?? 3,
        maxProjects: json['maxProjects'] ?? 10,
        maxStorageGB: json['maxStorageGB'] ?? 5,
        aiCredits: json['aiCredits'] ?? 100,
      );

  Map<String, dynamic> toJson() => {
        'maxMembers': maxMembers,
        'maxWorkspaces': maxWorkspaces,
        'maxProjects': maxProjects,
        'maxStorageGB': maxStorageGB,
        'aiCredits': aiCredits,
      };
}

class OrgSettings {
  final bool enforced2FA;
  final List<String> allowedAuthProviders;
  final List<String> ipWhitelist;
  final int sessionTimeoutMinutes;
  final int dataRetentionDays;

  const OrgSettings({
    this.enforced2FA = false,
    this.allowedAuthProviders = const [],
    this.ipWhitelist = const [],
    this.sessionTimeoutMinutes = 60,
    this.dataRetentionDays = 365,
  });

  factory OrgSettings.fromJson(Map<String, dynamic> json) => OrgSettings(
        enforced2FA: json['enforced2FA'] ?? false,
        allowedAuthProviders:
            List<String>.from(json['allowedAuthProviders'] ?? []),
        ipWhitelist: List<String>.from(json['ipWhitelist'] ?? []),
        sessionTimeoutMinutes: json['sessionTimeoutMinutes'] ?? 60,
        dataRetentionDays: json['dataRetentionDays'] ?? 365,
      );

  Map<String, dynamic> toJson() => {
        'enforced2FA': enforced2FA,
        'allowedAuthProviders': allowedAuthProviders,
        'ipWhitelist': ipWhitelist,
        'sessionTimeoutMinutes': sessionTimeoutMinutes,
        'dataRetentionDays': dataRetentionDays,
      };
}

class OrgSso {
  final bool enabled;
  final String? provider; // saml | oidc
  final String? entityId;
  final String? ssoUrl;
  final String? certificate;

  const OrgSso({
    this.enabled = false,
    this.provider,
    this.entityId,
    this.ssoUrl,
    this.certificate,
  });

  factory OrgSso.fromJson(Map<String, dynamic> json) => OrgSso(
        enabled: json['enabled'] ?? false,
        provider: json['provider'],
        entityId: json['entityId'],
        ssoUrl: json['ssoUrl'],
        certificate: json['certificate'],
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'provider': provider,
        'entityId': entityId,
        'ssoUrl': ssoUrl,
        'certificate': certificate,
      };
}

class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String tenantId;
  final String owner; // ObjectId ref -> String
  final String? logo;
  final String? favicon;
  final String primaryColor;
  final String? domain;
  final String? industry;
  final String? size; // 1-10 | 11-50 | 51-200 | 201-500 | 501-1000 | 1000+
  final String? website;
  final String? country;
  final String timezone;
  final String plan; // free | starter | professional | enterprise
  final OrgQuotas quotas;
  final OrgSettings settings;
  final OrgSso sso;
  final String status; // active | suspended | trial | cancelled
  final DateTime? trialEndsAt;
  final DateTime? suspendedAt;
  final String? suspendReason;
  final int memberCount;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.tenantId,
    required this.owner,
    this.logo,
    this.favicon,
    this.primaryColor = '#6366F1',
    this.domain,
    this.industry,
    this.size,
    this.website,
    this.country,
    this.timezone = 'UTC',
    this.plan = 'free',
    this.quotas = const OrgQuotas(),
    this.settings = const OrgSettings(),
    this.sso = const OrgSso(),
    this.status = 'active',
    this.trialEndsAt,
    this.suspendedAt,
    this.suspendReason,
    this.memberCount = 1,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
      OrganizationModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        tenantId: json['tenantId'] ?? '',
        owner: json['owner'] is Map
            ? json['owner']['_id'] ?? ''
            : json['owner'] ?? '',
        logo: json['logo'],
        favicon: json['favicon'],
        primaryColor: json['primaryColor'] ?? '#6366F1',
        domain: json['domain'],
        industry: json['industry'],
        size: json['size'],
        website: json['website'],
        country: json['country'],
        timezone: json['timezone'] ?? 'UTC',
        plan: json['plan'] ?? 'free',
        quotas: json['quotas'] != null
            ? OrgQuotas.fromJson(json['quotas'])
            : const OrgQuotas(),
        settings: json['settings'] != null
            ? OrgSettings.fromJson(json['settings'])
            : const OrgSettings(),
        sso: json['sso'] != null
            ? OrgSso.fromJson(json['sso'])
            : const OrgSso(),
        status: json['status'] ?? 'active',
        trialEndsAt: json['trialEndsAt'] != null
            ? DateTime.tryParse(json['trialEndsAt'])
            : null,
        suspendedAt: json['suspendedAt'] != null
            ? DateTime.tryParse(json['suspendedAt'])
            : null,
        suspendReason: json['suspendReason'],
        memberCount: json['memberCount'] ?? 1,
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
        'owner': owner,
        'logo': logo,
        'favicon': favicon,
        'primaryColor': primaryColor,
        'domain': domain,
        'industry': industry,
        'size': size,
        'website': website,
        'country': country,
        'timezone': timezone,
        'plan': plan,
        'quotas': quotas.toJson(),
        'settings': settings.toJson(),
        'sso': sso.toJson(),
        'status': status,
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'suspendedAt': suspendedAt?.toIso8601String(),
        'suspendReason': suspendReason,
        'memberCount': memberCount,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
