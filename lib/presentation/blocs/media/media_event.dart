part of 'media_bloc.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

class GenerateImageEvent extends MediaEvent {
  final String prompt;
  final Map<String, dynamic>? parameters;

  const GenerateImageEvent({
    required this.prompt,
    this.parameters,
  });

  @override
  List<Object?> get props => [prompt, parameters];
}

class GenerateAudioEvent extends MediaEvent {
  final String prompt;
  final Map<String, dynamic>? parameters;

  const GenerateAudioEvent({
    required this.prompt,
    this.parameters,
  });

  @override
  List<Object?> get props => [prompt, parameters];
}

class ClearMediaHistory extends MediaEvent {
  const ClearMediaHistory();
}