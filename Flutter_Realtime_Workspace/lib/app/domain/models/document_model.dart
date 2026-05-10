class DocumentFile {
  final String url;
  final String? publicId;
  final String filename;
  final String mimeType;
  final int? bytes;
  final String? checksum;

  const DocumentFile({
    required this.url,
    this.publicId,
    required this.filename,
    required this.mimeType,
    this.bytes,
    this.checksum,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) => DocumentFile(
        url: json['url'] ?? '',
        publicId: json['publicId'],
        filename: json['filename'] ?? '',
        mimeType: json['mimeType'] ?? '',
        bytes: json['bytes'],
        checksum: json['checksum'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'publicId': publicId,
        'filename': filename,
        'mimeType': mimeType,
        'bytes': bytes,
        'checksum': checksum,
      };
}

class DocumentMetadata {
  final int? pageCount;
  final int? wordCount;
  final String? author;
  final String? language;

  const DocumentMetadata({
    this.pageCount,
    this.wordCount,
    this.author,
    this.language,
  });

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) =>
      DocumentMetadata(
        pageCount: json['pageCount'],
        wordCount: json['wordCount'],
        author: json['author'],
        language: json['language'],
      );

  Map<String, dynamic> toJson() => {
        'pageCount': pageCount,
        'wordCount': wordCount,
        'author': author,
        'language': language,
      };
}

class DocumentSharedWith {
  final String userId;
  final String permission; // view | edit

  const DocumentSharedWith({required this.userId, this.permission = 'view'});

  factory DocumentSharedWith.fromJson(Map<String, dynamic> json) =>
      DocumentSharedWith(
        userId: json['userId'] is Map
            ? json['userId']['_id'] ?? ''
            : json['userId'] ?? '',
        permission: json['permission'] ?? 'view',
      );

  Map<String, dynamic> toJson() => {'userId': userId, 'permission': permission};
}

class DocumentVersion {
  final int version;
  final String url;
  final DateTime? uploadedAt;
  final String? uploadedBy;

  const DocumentVersion({
    required this.version,
    required this.url,
    this.uploadedAt,
    this.uploadedBy,
  });

  factory DocumentVersion.fromJson(Map<String, dynamic> json) =>
      DocumentVersion(
        version: json['version'] ?? 1,
        url: json['url'] ?? '',
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'])
            : null,
        uploadedBy: json['uploadedBy'] is Map
            ? json['uploadedBy']['_id']
            : json['uploadedBy'],
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'url': url,
        'uploadedAt': uploadedAt?.toIso8601String(),
        'uploadedBy': uploadedBy,
      };
}

class DocumentModel {
  final String id;
  final String title;
  final String tenantId;
  final String? orgId;
  final String? workspaceId;
  final String? projectId;
  final String uploadedBy; // was createdBy
  // type: pdf | docx | xlsx | pptx | image | video | audio | markdown | text | csv | other
  final String type;
  final DocumentFile file;
  final String? parsedContent;
  final DocumentMetadata? metadata;
  final bool indexed;
  final DateTime? indexedAt;
  final List<String> embeddingIds;
  final int chunkCount;
  // visibility: private | workspace | organization | public
  final String visibility;
  final List<DocumentSharedWith> sharedWith;
  final int version;
  final List<DocumentVersion> versions;
  final List<String> tags;
  // status: active | archived | deleted
  final String status;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.tenantId,
    this.orgId,
    this.workspaceId,
    this.projectId,
    required this.uploadedBy,
    required this.type,
    required this.file,
    this.parsedContent,
    this.metadata,
    this.indexed = false,
    this.indexedAt,
    this.embeddingIds = const [],
    this.chunkCount = 0,
    this.visibility = 'workspace',
    this.sharedWith = const [],
    this.version = 1,
    this.versions = const [],
    this.tags = const [],
    this.status = 'active',
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        workspaceId: json['workspaceId'] is Map
            ? json['workspaceId']['_id']
            : json['workspaceId'],
        projectId: json['projectId'] is Map
            ? json['projectId']['_id']
            : json['projectId'],
        uploadedBy: json['uploadedBy'] is Map
            ? json['uploadedBy']['_id'] ?? ''
            : json['uploadedBy'] ?? '',
        type: json['type'] ?? 'other',
        file: json['file'] != null
            ? DocumentFile.fromJson(json['file'])
            : DocumentFile(url: '', filename: '', mimeType: ''),
        parsedContent: json['parsedContent'],
        metadata: json['metadata'] != null
            ? DocumentMetadata.fromJson(json['metadata'])
            : null,
        indexed: json['indexed'] ?? false,
        indexedAt: json['indexedAt'] != null
            ? DateTime.tryParse(json['indexedAt'])
            : null,
        embeddingIds: List<String>.from(json['embeddingIds'] ?? []),
        chunkCount: json['chunkCount'] ?? 0,
        visibility: json['visibility'] ?? 'workspace',
        sharedWith: (json['sharedWith'] as List? ?? [])
            .map((s) =>
                DocumentSharedWith.fromJson(s as Map<String, dynamic>))
            .toList(),
        version: json['version'] ?? 1,
        versions: (json['versions'] as List? ?? [])
            .map((v) =>
                DocumentVersion.fromJson(v as Map<String, dynamic>))
            .toList(),
        tags: List<String>.from(json['tags'] ?? []),
        status: json['status'] ?? 'active',
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'])
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'tenantId': tenantId,
        'orgId': orgId,
        'workspaceId': workspaceId,
        'projectId': projectId,
        'uploadedBy': uploadedBy,
        'type': type,
        'file': file.toJson(),
        'parsedContent': parsedContent,
        'metadata': metadata?.toJson(),
        'indexed': indexed,
        'indexedAt': indexedAt?.toIso8601String(),
        'embeddingIds': embeddingIds,
        'chunkCount': chunkCount,
        'visibility': visibility,
        'sharedWith': sharedWith.map((s) => s.toJson()).toList(),
        'version': version,
        'versions': versions.map((v) => v.toJson()).toList(),
        'tags': tags,
        'status': status,
        'deletedAt': deletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
