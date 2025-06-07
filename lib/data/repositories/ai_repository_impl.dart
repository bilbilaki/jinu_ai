import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../datasources/ai_local_datasource.dart';
import '../models/message_model.dart';

class AIRepositoryImpl implements AIRepository {
  final AIRemoteDataSource remoteDataSource;
  final AILocalDataSource localDataSource;

  AIRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.sendMessage(
        content: content,
        history: history,
        parameters: parameters,
      );
      
      // Save to local storage
      final updatedHistory = [...history, result];
      await localDataSource.saveChatHistory(
        messages: updatedHistory.map((msg) => MessageModel.fromEntity(msg)).toList(),
      );
      
      return Right(result);
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<String>>> sendMessageStream({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await remoteDataSource.sendMessageStream(
        content: content,
        history: history,
        parameters: parameters,
      );
      return Right(result);
    } catch (e) {
      return Left(AIModelFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getChatHistory({
    String? conversationId,
    int? limit,
  }) async {
    try {
      final result = await localDataSource.getChatHistory(
        conversationId: conversationId,
      );
      
      final messages = result.cast<Message>();
      
      if (limit != null && messages.length > limit) {
        return Right(messages.take(limit).toList());
      }
      
      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveChatHistory({
    required List<Message> messages,
    String? conversationId,
  }) async {
    try {
      await localDataSource.saveChatHistory(
        messages: messages.map((msg) => MessageModel.fromEntity(msg)).toList(),
        conversationId: conversationId,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearChatHistory({
    String? conversationId,
  }) async {
    try {
      await localDataSource.clearChatHistory(conversationId: conversationId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableModels() async {
    try {
      final result = await remoteDataSource.getAvailableModels();
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getModelInfo(String modelId) async {
    try {
      final result = await remoteDataSource.getModelInfo(modelId);
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}