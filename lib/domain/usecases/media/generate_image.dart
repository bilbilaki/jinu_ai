import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/media_content.dart';
import '../../repositories/media_repository.dart';

class GenerateImage {
  final MediaRepository repository;

  GenerateImage(this.repository);

  Future<Either<Failure, MediaContent>> call({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.generateImage(
      prompt: prompt,
      parameters: parameters,
    );
  }

  Future<Either<Failure, Stream<MediaContent>>> callStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.generateImageStream(
      prompt: prompt,
      parameters: parameters,
    );
  }
}