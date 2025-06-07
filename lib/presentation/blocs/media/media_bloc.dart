import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/media_content.dart';
import '../../../domain/usecases/media/generate_image.dart';
import '../../../domain/usecases/media/generate_audio.dart';

part 'media_event.dart';
part 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final GenerateImage generateImage;
  final GenerateAudio generateAudio;

  MediaBloc({
    required this.generateImage,
    required this.generateAudio,
  }) : super(const MediaState()) {
    on<GenerateImageEvent>(_onGenerateImage);
    on<GenerateAudioEvent>(_onGenerateAudio);
    on<ClearMediaHistory>(_onClearMediaHistory);
  }

  Future<void> _onGenerateImage(
    GenerateImageEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(state.copyWith(isGenerating: true));

    final result = await generateImage(
      prompt: event.prompt,
      parameters: event.parameters,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isGenerating: false,
        error: failure.message,
      )),
      (mediaContent) => emit(state.copyWith(
        isGenerating: false,
        mediaHistory: [...state.mediaHistory, mediaContent],
        error: null,
      )),
    );
  }

  Future<void> _onGenerateAudio(
    GenerateAudioEvent event,
    Emitter<MediaState> emit,
  ) async {
    emit(state.copyWith(isGenerating: true));

    final result = await generateAudio(
      prompt: event.prompt,
      parameters: event.parameters,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isGenerating: false,
        error: failure.message,
      )),
      (mediaContent) => emit(state.copyWith(
        isGenerating: false,
        mediaHistory: [...state.mediaHistory, mediaContent],
        error: null,
      )),
    );
  }

  void _onClearMediaHistory(
    ClearMediaHistory event,
    Emitter<MediaState> emit,
  ) {
    emit(state.copyWith(
      mediaHistory: [],
      error: null,
    ));
  }
}