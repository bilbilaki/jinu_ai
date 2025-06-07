import 'package:equatable/equatable.dart';

enum MediaContentType { image, audio, video }
enum MediaStatus { generating, completed, failed }

class MediaContent extends Equatable {
  final String id;
  final String prompt;
  final MediaContentType type;
  final String? url;
  final String? localPath;
  final MediaStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? parameters;
  final String? error;
  final double? progress;

  const MediaContent({
    required this.id,
    required this.prompt,
    required this.type,
    this.url,
    this.localPath,
    required this.status,
    required this.createdAt,
    this.parameters,
    this.error,
    this.progress,
  });

  MediaContent copyWith({
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
    return MediaContent(
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

  @override
  List<Object?> get props => [
        id,
        prompt,
        type,
        url,
        localPath,
        status,
        createdAt,
        parameters,
        error,
        progress,
      ];
}