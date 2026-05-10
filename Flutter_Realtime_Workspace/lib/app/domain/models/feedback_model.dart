class FeedbackAttachment {
  final String url;
  final String? filename;

  const FeedbackAttachment({required this.url, this.filename});

  factory FeedbackAttachment.fromJson(Map<String, dynamic> json) =>
      FeedbackAttachment(url: json['url'] ?? '', filename: json['filename']);

  Map<String, dynamic> toJson() => {'url': url, 'filename': filename};
}

class FeedbackResponse {
  final String content;
  final String respondedBy;
  final DateTime respondedAt;

  const FeedbackResponse({
    required this.content,
    required this.respondedBy,
    required this.respondedAt,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) =>
      FeedbackResponse(
        content: json['content'] ?? '',
        respondedBy: json['respondedBy'] is Map
            ? json['respondedBy']['_id'] ?? ''
            : json['respondedBy'] ?? '',
        respondedAt:
            DateTime.tryParse(json['respondedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'respondedBy': respondedBy,
        'respondedAt': respondedAt.toIso8601String(),
      };
}

class FeedbackMetadata {
  final String? page;
  final String? browser;
  final String? os;

  const FeedbackMetadata({this.page, this.browser, this.os});

  factory FeedbackMetadata.fromJson(Map<String, dynamic> json) =>
      FeedbackMetadata(
        page: json['page'],
        browser: json['browser'],
        os: json['os'],
      );

  Map<String, dynamic> toJson() => {'page': page, 'browser': browser, 'os': os};
}

class FeedbackModel {
  final String id;
  final String tenantId;
  final String userId; // was submittedBy
  // type: bug | feature | improvement | praise | complaint | survey
  final String type;
  final String title;
  final String? description;
  final int? rating; // 1-5
  final String? category;
  // status: new | acknowledged | in_progress | resolved | closed
  final String status;
  // priority: low | medium | high
  final String priority;
  final List<FeedbackAttachment> attachments;
  final FeedbackResponse? response;
  final FeedbackMetadata? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeedbackModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    this.type = 'feature',
    required this.title,
    this.description,
    this.rating,
    this.category,
    this.status = 'new',
    this.priority = 'medium',
    this.attachments = const [],
    this.response,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        type: json['type'] ?? 'feature',
        title: json['title'] ?? '',
        description: json['description'],
        rating: json['rating'],
        category: json['category'],
        status: json['status'] ?? 'new',
        priority: json['priority'] ?? 'medium',
        attachments: (json['attachments'] as List? ?? [])
            .map((a) =>
                FeedbackAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        response: json['response'] != null
            ? FeedbackResponse.fromJson(
                json['response'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] != null
            ? FeedbackMetadata.fromJson(
                json['metadata'] as Map<String, dynamic>)
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'userId': userId,
        'type': type,
        'title': title,
        'description': description,
        'rating': rating,
        'category': category,
        'status': status,
        'priority': priority,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'response': response?.toJson(),
        'metadata': metadata?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
