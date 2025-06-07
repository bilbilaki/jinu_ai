import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/message.dart';
import '../../repositories/ai_repository.dart';

class SendMessage {
  final AIRepository repository;

  SendMessage(this.repository);

  Future<Either<Failure, Message>> call({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.sendMessage(
      content: content,
      history: history,
      parameters: parameters,
    );
  }

  Future<Either<Failure, Stream<String>>> callStream({
    required String content,
    required List<Message> history,
    Map<String, dynamic>? parameters,
  }) async {
    return await repository.sendMessageStream(
      content: content,
      history: history,
      parameters: parameters,
    );
  }
}