part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends ChatEvent {
  final String? conversationId;
  final int? limit;

  const LoadChatHistory({this.conversationId, this.limit});

  @override
  List<Object?> get props => [conversationId, limit];
}

class SendChatMessage extends ChatEvent {
  final String content;
  final Map<String, dynamic>? parameters;

  const SendChatMessage({
    required this.content,
    this.parameters,
  });

  @override
  List<Object?> get props => [content, parameters];
}

class SendStreamingMessage extends ChatEvent {
  final String content;
  final Map<String, dynamic>? parameters;

  const SendStreamingMessage({
    required this.content,
    this.parameters,
  });

  @override
  List<Object?> get props => [content, parameters];
}

class UpdateStreamingMessage extends ChatEvent {
  final String chunk;

  const UpdateStreamingMessage(this.chunk);

  @override
  List<Object> get props => [chunk];
}

class ClearChat extends ChatEvent {
  const ClearChat();
}