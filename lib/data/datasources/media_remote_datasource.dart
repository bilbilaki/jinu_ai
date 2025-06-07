import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_content_model.dart';
import '../../domain/entities/media_content.dart';

abstract class MediaRemoteDataSource {
  Future<MediaContentModel> generateImage({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Stream<MediaContentModel>> generateImageStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<MediaContentModel> generateAudio({
    required String prompt,
    Map<String, dynamic>? parameters,
  });

  Future<Stream<MediaContentModel>> generateAudioStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  });
}

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  MediaRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://api.openai.com/v1',
  });

  @override
  Future<MediaContentModel> generateImage({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    final requestBody = {
      'prompt': prompt,
      'n': parameters?['n'] ?? 1,
      'size': parameters?['size'] ?? '1024x1024',
      'response_format': parameters?['response_format'] ?? 'url',
      ...?parameters,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/images/generations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${parameters?['api_key'] ?? ''}',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageData = data['data'][0];
      
      return MediaContentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        type: MediaContentType.image,
        url: imageData['url'],
        status: MediaStatus.completed,
        createdAt: DateTime.now(),
        parameters: parameters,
      );
    } else {
      throw Exception('Failed to generate image: ${response.body}');
    }
  }

  @override
  Future<Stream<MediaContentModel>> generateImageStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    // Implementation for streaming image generation
    throw UnimplementedError('Image streaming not implemented yet');
  }

  @override
  Future<MediaContentModel> generateAudio({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    final requestBody = {
      'model': parameters?['model'] ?? 'tts-1',
      'input': prompt,
      'voice': parameters?['voice'] ?? 'alloy',
      'response_format': parameters?['response_format'] ?? 'mp3',
      ...?parameters,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/audio/speech'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${parameters?['api_key'] ?? ''}',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      // For audio, we typically get binary data
      // This would need to be saved to a file and return the local path
      return MediaContentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        type: MediaContentType.audio,
        status: MediaStatus.completed,
        createdAt: DateTime.now(),
        parameters: parameters,
      );
    } else {
      throw Exception('Failed to generate audio: ${response.body}');
    }
  }

  @override
  Future<Stream<MediaContentModel>> generateAudioStream({
    required String prompt,
    Map<String, dynamic>? parameters,
  }) async {
    // Implementation for streaming audio generation
    throw UnimplementedError('Audio streaming not implemented yet');
  }
}