class AssetVariant {
  final String name;
  final String url;
  final int? width;
  final int? height;

  const AssetVariant({
    required this.name,
    required this.url,
    this.width,
    this.height,
  });

  factory AssetVariant.fromJson(Map<String, dynamic> json) => AssetVariant(
        name: json['name'] ?? '',
        url: json['url'] ?? '',
        width: json['width'],
        height: json['height'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'width': width,
        'height': height,
      };
}

class AssetAttachedTo {
  // type: project | task | channel | meeting | document | profile
  final String? type;
  final String? id;

  const AssetAttachedTo({this.type, this.id});

  factory AssetAttachedTo.fromJson(Map<String, dynamic> json) =>
      AssetAttachedTo(type: json['type'], id: json['id']);

  Map<String, dynamic> toJson() => {'type': type, 'id': id};
}

// Renamed from StorageFileModel to AssetModel to match backend asset.model.js
class AssetModel {
  final String id;
  final String tenantId;
  final String uploadedBy;
  final String filename;
  final String originalName;
  final String mimeType;
  final int bytes;
  final String url;
  final String? publicId;
  // resourceType: image | video | audio | document | raw
  final String resourceType;
  final String folder;
  final String? thumbnailUrl;
  final List<AssetVariant> variants;
  final int? width;
  final int? height;
  final double? duration;
  final String? checksum;
  final AssetAttachedTo? attachedTo;
  // status: processing | ready | error | deleted
  final String status;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssetModel({
    required this.id,
    required this.tenantId,
    required this.uploadedBy,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.bytes,
    required this.url,
    this.publicId,
    this.resourceType = 'raw',
    this.folder = 'general',
    this.thumbnailUrl,
    this.variants = const [],
    this.width,
    this.height,
    this.duration,
    this.checksum,
    this.attachedTo,
    this.status = 'ready',
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        uploadedBy: json['uploadedBy'] is Map
            ? json['uploadedBy']['_id'] ?? ''
            : json['uploadedBy'] ?? '',
        filename: json['filename'] ?? '',
        originalName: json['originalName'] ?? '',
        mimeType: json['mimeType'] ?? 'application/octet-stream',
        bytes: json['bytes'] ?? 0,
        url: json['url'] ?? '',
        publicId: json['publicId'],
        resourceType: json['resourceType'] ?? 'raw',
        folder: json['folder'] ?? 'general',
        thumbnailUrl: json['thumbnailUrl'],
        variants: (json['variants'] as List? ?? [])
            .map((v) => AssetVariant.fromJson(v as Map<String, dynamic>))
            .toList(),
        width: json['width'],
        height: json['height'],
        duration: (json['duration'] as num?)?.toDouble(),
        checksum: json['checksum'],
        attachedTo: json['attachedTo'] != null
            ? AssetAttachedTo.fromJson(
                json['attachedTo'] as Map<String, dynamic>)
            : null,
        status: json['status'] ?? 'ready',
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
        'tenantId': tenantId,
        'uploadedBy': uploadedBy,
        'filename': filename,
        'originalName': originalName,
        'mimeType': mimeType,
        'bytes': bytes,
        'url': url,
        'publicId': publicId,
        'resourceType': resourceType,
        'folder': folder,
        'thumbnailUrl': thumbnailUrl,
        'variants': variants.map((v) => v.toJson()).toList(),
        'width': width,
        'height': height,
        'duration': duration,
        'checksum': checksum,
        'attachedTo': attachedTo?.toJson(),
        'status': status,
        'deletedAt': deletedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  // Helpers
  String get sizeFormatted {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isPdf => mimeType == 'application/pdf';
}

// Alias for backward compatibility
typedef StorageFileModel = AssetModel;
