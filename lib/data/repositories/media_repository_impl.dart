import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/media_content.dart';
import '../../domain/repositories/media_repository.dart';
import '../datasources/media_remote_datasource.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;

  MediaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MediaContent>> generateImage({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.generateImage(
        prompt: prompt,
        parameters: parameters,
      );
      return Right(result);
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<MediaContent>>> generateImageStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.generateImageStream(
        prompt: prompt,
        parameters: parameters,
      );
      return Right(result.cast<MediaContent>());
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaContent>> generateAudio({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.generateAudio(
        prompt: prompt,
        parameters: parameters,
      );
      return Right(result);
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<MediaContent>>> generateAudioStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.generateAudioStream(
        prompt: prompt,
        parameters: parameters,
      );
      return Right(result.cast<MediaContent>());
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaContent>> generateVideo({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    // Video generation not implemented yet
    return Left(UnknownFailure(message: 'Video generation not implemented'));
  }

  @override
  Future<Either<Failure, List<MediaContent>>> getMediaHistory({
    MediaContentType? type,
    int? limit,
  }) async {
    // Implementation would depend on local storage for media history
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveMediaContent(MediaContent content) async {
    // Implementation for saving media content locally
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteMediaContent(String id) async {
    // Implementation for deleting media content
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> downloadMedia({
    required String url,
    required String fileName,
  }) async {
    // Implementation for downloading media files
    return Left(UnknownFailure(message: 'Download not implemented'));
  }
}