import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/media_content.dart';

abstract class MediaRepository {
  Future<Either<Failure, MediaContent>> generateImage({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, Stream<MediaContent>>> generateImageStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, MediaContent>> generateAudio({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, Stream<MediaContent>>> generateAudioStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, MediaContent>> generateVideo({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, List<MediaContent>>> getMediaHistory({
    MediaContentType? type,
    int? limit,
  });

  Future<Either<Failure, void>> saveMediaContent(MediaContent content);

  Future<Either<Failure, void>> deleteMediaContent(String id);

  Future<Either<Failure, String>> downloadMedia({
    required String url,
    required String fileName,
  });
}