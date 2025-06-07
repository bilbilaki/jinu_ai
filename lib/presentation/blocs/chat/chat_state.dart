part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isStreaming, error];
}