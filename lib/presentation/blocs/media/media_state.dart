part of 'media_bloc.dart';

class MediaState extends Equatable {
  final List<MediaContent> mediaHistory;
  final bool isGenerating;
  final String? error;

  const MediaState({
    this.mediaHistory = const [],
    this.isGenerating = false,
    this.error,
  });

  MediaState copyWith({
    List<MediaContent>? mediaHistory,
    bool? isGenerating,
    String? error,
  }) {
    return MediaState(
      mediaHistory: mediaHistory ?? this.mediaHistory,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }

  @override
  List<Object?> get props => [mediaHistory, isGenerating, error];
}