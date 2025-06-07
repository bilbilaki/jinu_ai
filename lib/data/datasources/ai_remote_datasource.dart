import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../../domain/entities/message.dart';

abstract class AIRemoteDataSource {
  Future<MessageModel> sendMessage({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  });

  Future<Stream<String>> sendMessageStream({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  });

  Future<List<String>> getAvailableModels();
  Future<Map<String, dynamic>> getModelInfo(String modelId);
}

class AIRemoteDataSourceImpl implements AIRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  AIRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://api.openai.com/v1', // Default to OpenAI API
  });

  @override
  Future<MessageModel> sendMessage({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    final messages = [
      ...history.map((msg) => {
        'role': msg.role.toString().split('.').last,
        'content': msg.content,
      }),
      {
        'role': 'user',
        'content': content,
      },
    ];

    final requestBody = {
      'model': parameters?['model'] ?? 'gpt-3.5-turbo',
      'messages': messages,
      'temperature': parameters?['temperature'] ?? 0.7,
      'max_tokens': parameters?['max_tokens'] ?? 4096,
      ...?parameters,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${parameters?['api_key'] ?? ''}',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final assistantMessage = data['choices'][0]['message'];
      
      return MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: assistantMessage['content'],
        type: MessageType.text,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'model': data['model'],
          'usage': data['usage'],
        },
      );
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  @override
  Future<Stream<String>> sendMessageStream({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    // Implementation for streaming responses
    // This would typically use Server-Sent Events or WebSockets
    throw UnimplementedError('Streaming not implemented yet');
  }

  @override
  Future<List<String>> getAvailableModels() async {
    final response = await client.get(
      Uri.parse('$baseUrl/models'),
      headers: {
        'Authorization': 'Bearer ', // TODO: Add API key parameter
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((model) => model['id'] as String)
          .toList();
    } else {
      throw Exception('Failed to get models: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> getModelInfo(String modelId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/models/$modelId'),
      headers: {
        'Authorization': 'Bearer ', // TODO: Add API key parameter
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get model info: ${response.body}');
    }
  }
}
