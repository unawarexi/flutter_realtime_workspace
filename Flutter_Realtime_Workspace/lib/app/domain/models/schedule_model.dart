class ScheduleModel {
  final String id;
  final String title;
  final String? description;
  final String workspaceId;
  final String orgId;
  final String createdBy;
  final List<String> attendeeIds;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? recurrenceRule;
  final String? location;
  final String? meetingLink;
  final String type;
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.title,
    this.description,
    required this.workspaceId,
    required this.orgId,
    required this.createdBy,
    this.attendeeIds = const [],
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.recurrenceRule,
    this.location,
    this.meetingLink,
    this.type = 'event',
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        workspaceId: json['workspaceId'] ?? '',
        orgId: json['orgId'] ?? '',
        createdBy: json['createdBy'] ?? '',
        attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
        startTime:
            DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(json['endTime'] ?? '') ??
            DateTime.now().add(const Duration(hours: 1)),
        isAllDay: json['isAllDay'] ?? false,
        recurrenceRule: json['recurrenceRule'],
        location: json['location'],
        meetingLink: json['meetingLink'],
        type: json['type'] ?? 'event',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'workspaceId': workspaceId,
        'orgId': orgId,
        'createdBy': createdBy,
        'attendeeIds': attendeeIds,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isAllDay': isAllDay,
        'recurrenceRule': recurrenceRule,
        'location': location,
        'meetingLink': meetingLink,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };
}
