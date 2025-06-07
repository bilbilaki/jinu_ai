import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/message.dart';
import '../../repositories/ai_repository.dart';

class GetChatHistory {
  final AIRepository repository;

  GetChatHistory(this.repository);

  Future<Either<Failure, List<Message>>> call({
    String? conversationId,
    int? limit,
  }) async {
    return await repository.getChatHistory(
      conversationId: conversationId,
      limit: limit,
    );
  }
}