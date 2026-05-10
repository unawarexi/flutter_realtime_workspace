class MessageAttachment {
  final String url;
  final String? publicId;
  final String? filename;
  final String? mimeType;
  final int? bytes;
  final int? width;
  final int? height;

  const MessageAttachment({
    required this.url,
    this.publicId,
    this.filename,
    this.mimeType,
    this.bytes,
    this.width,
    this.height,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        url: json['url'] ?? '',
        publicId: json['publicId'],
        filename: json['filename'],
        mimeType: json['mimeType'],
        bytes: json['bytes'],
        width: json['width'],
        height: json['height'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'publicId': publicId,
        'filename': filename,
        'mimeType': mimeType,
        'bytes': bytes,
        'width': width,
        'height': height,
      };
}

class MessageReaction {
  final String emoji;
  final List<String> users;
  final int count;

  const MessageReaction({
    required this.emoji,
    this.users = const [],
    this.count = 0,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        emoji: json['emoji'] ?? '',
        users: (json['users'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        count: json['count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'users': users,
        'count': count,
      };
}

class MessageEditHistory {
  final String content;
  final DateTime editedAt;

  const MessageEditHistory({required this.content, required this.editedAt});

  factory MessageEditHistory.fromJson(Map<String, dynamic> json) =>
      MessageEditHistory(
        content: json['content'] ?? '',
        editedAt:
            DateTime.tryParse(json['editedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'editedAt': editedAt.toIso8601String(),
      };
}

// Embedded UserInfo for sender
class MessageSender {
  final String id;
  final String? email;
  final String? fullName;
  final String? profilePicture;

  const MessageSender({
    required this.id,
    this.email,
    this.fullName,
    this.profilePicture,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) => MessageSender(
        id: json['_id'] ?? json['id'] ?? '',
        email: json['email'],
        fullName: json['fullName'],
        profilePicture: json['profilePicture'],
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'fullName': fullName,
        'profilePicture': profilePicture,
      };
}

class MessageModel {
  final String id;
  final String channelId;
  final String tenantId;
  final MessageSender sender; // senderId with embedded UserInfo
  final String? content;
  // contentType: text | image | video | audio | file | system | ai_response
  final String contentType;
  final List<MessageAttachment> attachments;
  final String? threadId; // parent message ref
  final int threadReplyCount;
  final DateTime? threadLastReplyAt;
  final List<String> mentions; // user ids
  final bool mentionsEveryone;
  final List<MessageReaction> reactions;
  final bool edited;
  final DateTime? editedAt;
  final List<MessageEditHistory> editHistory;
  final bool deleted;
  final DateTime? deletedAt;
  final bool pinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageModel({
    required this.id,
    required this.channelId,
    required this.tenantId,
    required this.sender,
    this.content,
    this.contentType = 'text',
    this.attachments = const [],
    this.threadId,
    this.threadReplyCount = 0,
    this.threadLastReplyAt,
    this.mentions = const [],
    this.mentionsEveryone = false,
    this.reactions = const [],
    this.edited = false,
    this.editedAt,
    this.editHistory = const [],
    this.deleted = false,
    this.deletedAt,
    this.pinned = false,
    this.pinnedAt,
    this.pinnedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['_id'] ?? json['id'] ?? '',
        channelId: json['channelId'] is Map
            ? json['channelId']['_id'] ?? ''
            : json['channelId'] ?? '',
        tenantId: json['tenantId'] ?? '',
        sender: json['senderId'] is Map
            ? MessageSender.fromJson(json['senderId'] as Map<String, dynamic>)
            : MessageSender(id: json['senderId'] ?? ''),
        content: json['content'],
        contentType: json['contentType'] ?? 'text',
        attachments: (json['attachments'] as List? ?? [])
            .map((a) =>
                MessageAttachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        threadId: json['threadId'] is Map
            ? json['threadId']['_id']
            : json['threadId'],
        threadReplyCount: json['threadReplyCount'] ?? 0,
        threadLastReplyAt: json['threadLastReplyAt'] != null
            ? DateTime.tryParse(json['threadLastReplyAt'])
            : null,
        mentions: (json['mentions'] as List? ?? [])
            .map((e) => e is Map ? e['_id'] as String? ?? '' : e as String)
            .toList(),
        mentionsEveryone: json['mentionsEveryone'] ?? false,
        reactions: (json['reactions'] as List? ?? [])
            .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
            .toList(),
        edited: json['edited'] ?? false,
        editedAt: json['editedAt'] != null
            ? DateTime.tryParse(json['editedAt'])
            : null,
        editHistory: (json['editHistory'] as List? ?? [])
            .map((e) =>
                MessageEditHistory.fromJson(e as Map<String, dynamic>))
            .toList(),
        deleted: json['deleted'] ?? false,
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'])
            : null,
        pinned: json['pinned'] ?? false,
        pinnedAt: json['pinnedAt'] != null
            ? DateTime.tryParse(json['pinnedAt'])
            : null,
        pinnedBy: json['pinnedBy'] is Map
            ? json['pinnedBy']['_id']
            : json['pinnedBy'],
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'channelId': channelId,
        'tenantId': tenantId,
        'senderId': sender.toJson(),
        'content': content,
        'contentType': contentType,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'threadId': threadId,
        'threadReplyCount': threadReplyCount,
        'threadLastReplyAt': threadLastReplyAt?.toIso8601String(),
        'mentions': mentions,
        'mentionsEveryone': mentionsEveryone,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'edited': edited,
        'editedAt': editedAt?.toIso8601String(),
        'editHistory': editHistory.map((e) => e.toJson()).toList(),
        'deleted': deleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'pinned': pinned,
        'pinnedAt': pinnedAt?.toIso8601String(),
        'pinnedBy': pinnedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
