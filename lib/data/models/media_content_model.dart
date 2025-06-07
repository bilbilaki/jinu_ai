import '../../domain/entities/media_content.dart';

class MediaContentModel extends MediaContent {
  const MediaContentModel({
    required super.id,
    required super.prompt,
    required super.type,
    super.url,
    super.localPath,
    required super.status,
    required super.createdAt,
    super.parameters,
    super.error,
    super.progress,
  });

  factory MediaContentModel.fromJson(Map<String, dynamic> json) {
    return MediaContentModel(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      type: MediaContentType.values.firstWhere(
        (e) => e.toString() == 'MediaContentType.${json['type']}',
        orElse: () => MediaContentType.image,
      ),
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
      status: MediaStatus.values.firstWhere(
        (e) => e.toString() == 'MediaStatus.${json['status']}',
        orElse: () => MediaStatus.generating,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      parameters: json['parameters'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      progress: json['progress'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'type': type.toString().split('.').last,
      'url': url,
      'localPath': localPath,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'parameters': parameters,
      'error': error,
      'progress': progress,
    };
  }

  factory MediaContentModel.fromEntity(MediaContent content) {
    return MediaContentModel(
      id: content.id,
      prompt: content.prompt,
      type: content.type,
      url: content.url,
      localPath: content.localPath,
      status: content.status,
      createdAt: content.createdAt,
      parameters: content.parameters,
      error: content.error,
      progress: content.progress,
    );
  }

  MediaContentModel copyWith({
    String? id,
    String? prompt,
    MediaContentType? type,
    String? url,
    String? localPath,
    MediaStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? parameters,
    String? error,
    double? progress,
  }) {
    return MediaContentModel(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      parameters: parameters ?? this.parameters,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}