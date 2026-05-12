class RecordingModel {
  final String id;
  final String scheduleId;
  final String? meetingId;
  final String? title;
  final String? url;
  final int? durationSeconds;
  final int? fileSizeBytes;
  final DateTime? recordedAt;
  final DateTime createdAt;

  const RecordingModel({
    required this.id,
    required this.scheduleId,
    this.meetingId,
    this.title,
    this.url,
    this.durationSeconds,
    this.fileSizeBytes,
    this.recordedAt,
    required this.createdAt,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) => RecordingModel(
        id: json['_id'] ?? json['id'] ?? '',
        scheduleId: json['scheduleId'] ?? '',
        meetingId: json['meetingId'],
        title: json['title'],
        url: json['url'],
        durationSeconds: json['durationSeconds'],
        fileSizeBytes: json['fileSizeBytes'],
        recordedAt: json['recordedAt'] != null
            ? DateTime.tryParse(json['recordedAt'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleId': scheduleId,
        'meetingId': meetingId,
        'title': title,
        'url': url,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'recordedAt': recordedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
