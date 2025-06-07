import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/media_content.dart';
import '../../repositories/media_repository.dart';

class GenerateAudio {
  final MediaRepository repository;

  GenerateAudio(this.repository);

  Future<Either<Failure, MediaContent>> call({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.generateAudio(
      prompt: prompt,
      parameters: parameters,
    );
  }

  Future<Either<Failure, Stream<MediaContent>>> callStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.generateAudioStream(
      prompt: prompt,
      parameters: parameters,
    );
  }
}