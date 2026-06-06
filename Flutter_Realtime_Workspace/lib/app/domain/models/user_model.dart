class UserWorkingHours {
  final String? start;
  final String? end;

  const UserWorkingHours({this.start, this.end});

  factory UserWorkingHours.fromJson(Map json) {
    final safeJson = json is Map<String, dynamic>
        ? json
        : json.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
    return UserWorkingHours(
      start: safeJson['start'],
      end: safeJson['end'],
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class UserSocialLinks {
  final String? linkedIn;
  final String? github;
  final String? twitter;
  final String? website;

  const UserSocialLinks({this.linkedIn, this.github, this.twitter, this.website});

  factory UserSocialLinks.fromJson(Map json) {
    final safeJson = json is Map<String, dynamic>
        ? json
        : json.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
    return UserSocialLinks(
      linkedIn: safeJson['linkedIn'],
      github: safeJson['github'],
      twitter: safeJson['twitter'],
      website: safeJson['website'],
    );
  }

  Map<String, dynamic> toJson() => {
        'linkedIn': linkedIn,
        'github': github,
        'twitter': twitter,
        'website': website,
      };
}

class UserModel {
  final String id;
  final String firebaseUid;
  final String email;
  final String fullName;
  final String? displayName;
  final String? profilePicture; // was avatar
  final String? bio;
  final String? phoneNumber;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? lastLoginAt;
  // permissionsLevel: super_admin | admin | manager | employee | member | guest
  final String permissionsLevel; // replaces UserRole enum
  final String? tenantId;
  final String? orgId;
  final List<String> workspaceIds;
  // Profile / professional info
  final String? roleTitle;
  final String? department;
  // workType: Full-time | Part-time | Freelancer | Intern | Contractor
  final String? workType;
  final String? timezone;
  final UserWorkingHours? workingHours;
  final String? companyName;
  final String? companyWebsite;
  final String? industry;
  // teamSize: 1-10 | 11-50 | 51-100 | 100+
  final String? teamSize;
  final String? officeLocation;
  final List<String> interestsSkills;
  final UserSocialLinks? socialLinks;
  final int profileCompletion;
  final bool totpEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    this.displayName,
    this.profilePicture,
    this.bio,
    this.phoneNumber,
    this.isOnline = false,
    this.lastSeenAt,
    this.lastLoginAt,
    this.permissionsLevel = 'member',
    this.tenantId,
    this.orgId,
    this.workspaceIds = const [],
    this.roleTitle,
    this.department,
    this.workType,
    this.timezone,
    this.workingHours,
    this.companyName,
    this.companyWebsite,
    this.industry,
    this.teamSize,
    this.officeLocation,
    this.interestsSkills = const [],
    this.socialLinks,
    this.profileCompletion = 0,
    this.totpEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map json) {
    final safeJson = json is Map<String, dynamic>
        ? json
        : json.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );

    final workspaceIds = (safeJson['workspaceIds'] as List?)
            ?.map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList() ??
        [];

    final interestsSkills = (safeJson['interestsSkills'] as List?)
            ?.map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList() ??
        [];

    return UserModel(
      id: safeJson['_id'] ?? safeJson['id'] ?? '',
      firebaseUid: safeJson['firebaseUid'] ?? '',
      email: safeJson['email'] ?? '',
      fullName: safeJson['fullName'] ?? '',
      displayName: safeJson['displayName'] as String?,
      profilePicture: safeJson['profilePicture'] ?? safeJson['avatar'] as String?,
      bio: safeJson['bio'] as String?,
      phoneNumber: safeJson['phoneNumber'] as String?,
      isOnline: safeJson['isOnline'] as bool? ?? false,
      lastSeenAt: safeJson['lastSeenAt'] != null
          ? DateTime.tryParse(safeJson['lastSeenAt'].toString())
          : null,
      lastLoginAt: safeJson['lastLoginAt'] != null
          ? DateTime.tryParse(safeJson['lastLoginAt'].toString())
          : null,
      permissionsLevel:
          (safeJson['permissionsLevel'] ?? safeJson['role'] ?? 'member')
              .toString(),
      tenantId: safeJson['tenantId'] is Map
          ? safeJson['tenantId']['_id'] ?? safeJson['tenantId']
          : safeJson['tenantId'] as String?,
      orgId: safeJson['orgId'] is Map
          ? safeJson['orgId']['_id'] ?? safeJson['orgId']
          : safeJson['orgId'] as String?,
      workspaceIds: workspaceIds,
      roleTitle: safeJson['roleTitle'] as String?,
      department: safeJson['department'] as String?,
      workType: safeJson['workType'] as String?,
      timezone: safeJson['timezone'] as String?,
      workingHours: safeJson['workingHours'] != null
          ? UserWorkingHours.fromJson(safeJson['workingHours'])
          : null,
      companyName: safeJson['companyName'] as String?,
      companyWebsite: safeJson['companyWebsite'] as String?,
      industry: safeJson['industry'] as String?,
      teamSize: safeJson['teamSize'] as String?,
      officeLocation: safeJson['officeLocation'] as String?,
      interestsSkills: interestsSkills,
      socialLinks: safeJson['socialLinks'] != null
          ? UserSocialLinks.fromJson(safeJson['socialLinks'])
          : null,
      profileCompletion: (safeJson['profileCompletion'] is int)
          ? safeJson['profileCompletion'] as int
          : int.tryParse(safeJson['profileCompletion']?.toString() ?? '') ?? 0,
      totpEnabled: safeJson['totpEnabled'] as bool? ?? false,
      createdAt: DateTime.tryParse(safeJson['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              safeJson['updatedAt']?.toString() ?? safeJson['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'firebaseUid': firebaseUid,
        'email': email,
        'fullName': fullName,
        'displayName': displayName,
        'profilePicture': profilePicture,
        'bio': bio,
        'phoneNumber': phoneNumber,
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'permissionsLevel': permissionsLevel,
        'tenantId': tenantId,
        'orgId': orgId,
        'workspaceIds': workspaceIds,
        'roleTitle': roleTitle,
        'department': department,
        'workType': workType,
        'timezone': timezone,
        'workingHours': workingHours?.toJson(),
        'companyName': companyName,
        'companyWebsite': companyWebsite,
        'industry': industry,
        'teamSize': teamSize,
        'officeLocation': officeLocation,
        'interestsSkills': interestsSkills,
        'socialLinks': socialLinks?.toJson(),
        'profileCompletion': profileCompletion,
        'totpEnabled': totpEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toCacheJson() => {
        '_id': id,
        'firebaseUid': firebaseUid,
        'email': email,
        'fullName': fullName,
        'displayName': displayName,
        'profilePicture': profilePicture,
        'permissionsLevel': permissionsLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? fullName,
    String? displayName,
    String? email,
    String? profilePicture,
    String? bio,
    bool? isOnline,
    DateTime? lastSeenAt,
    String? permissionsLevel,
  }) =>
      UserModel(
        id: id,
        firebaseUid: firebaseUid,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        displayName: displayName ?? this.displayName,
        profilePicture: profilePicture ?? this.profilePicture,
        bio: bio ?? this.bio,
        phoneNumber: phoneNumber,
        isOnline: isOnline ?? this.isOnline,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        lastLoginAt: lastLoginAt,
        permissionsLevel: permissionsLevel ?? this.permissionsLevel,
        tenantId: tenantId,
        orgId: orgId,
        workspaceIds: workspaceIds,
        roleTitle: roleTitle,
        department: department,
        workType: workType,
        timezone: timezone,
        workingHours: workingHours,
        companyName: companyName,
        companyWebsite: companyWebsite,
        industry: industry,
        teamSize: teamSize,
        officeLocation: officeLocation,
        interestsSkills: interestsSkills,
        socialLinks: socialLinks,
        profileCompletion: profileCompletion,
        totpEnabled: totpEnabled,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

class DeviceModel {
  final String id;
  final String fcmToken;
  final String platform;
  final DateTime createdAt;

  const DeviceModel({
    required this.id,
    required this.fcmToken,
    required this.platform,
    required this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id: json['_id'] ?? json['id'] ?? '',
        fcmToken: json['fcmToken'] ?? '',
        platform: json['platform'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
