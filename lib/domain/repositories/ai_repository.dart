import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/message.dart';

abstract class AIRepository {
  Future<Either<Failure, Message>> sendMessage({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, Stream<String>>> sendMessageStream({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  });

  Future<Either<Failure, List<Message>>> getChatHistory({
    String? conversationId,
    int? limit,
  });

  Future<Either<Failure, void>> saveChatHistory({
    required List<Message> messages,
    String? conversationId,
  });

  Future<Either<Failure, void>> clearChatHistory({
    String? conversationId,
  });

  Future<Either<Failure, List<String>>> getAvailableModels();

  Future<Either<Failure, Map<String, dynamic>>> getModelInfo(String modelId);
}