import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/usecases/chat/send_message.dart';
import '../../../domain/usecases/chat/get_chat_history.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final GetChatHistory getChatHistory;

  ChatBloc({
    required this.sendMessage,
    required this.getChatHistory,
  }) : super(const ChatState()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendChatMessage>(_onSendChatMessage);
    on<SendStreamingMessage>(_onSendStreamingMessage);
    on<ClearChat>(_onClearChat);
    on<UpdateStreamingMessage>(_onUpdateStreamingMessage);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await getChatHistory(
      conversationId: event.conversationId,
      limit: event.limit,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (messages) => emit(state.copyWith(
        isLoading: false,
        messages: messages,
        error: null,
      )),
    );
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
      type: MessageType.text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      isLoading: true,
    ));

    final result = await sendMessage(
      content: event.content,
      history: state.messages,
      parameters: event.parameters,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (assistantMessage) => emit(state.copyWith(
        isLoading: false,
        messages: [...updatedMessages, assistantMessage],
        error: null,
      )),
    );
  }

  Future<void> _onSendStreamingMessage(
    SendStreamingMessage event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
      type: MessageType.text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final loadingMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      type: MessageType.text,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    final updatedMessages = [...state.messages, userMessage, loadingMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      isStreaming: true,
    ));

    final result = await sendMessage.callStream(
      content: event.content,
      history: state.messages,
      parameters: event.parameters,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isStreaming: false,
        error: failure.message,
      )),
      (stream) {
        // Handle streaming response
        stream.listen(
          (chunk) => add(UpdateStreamingMessage(chunk)),
          onError: (error) => emit(state.copyWith(
            isStreaming: false,
            error: error.toString(),
          )),
          onDone: () => emit(state.copyWith(isStreaming: false)),
        );
      },
    );
  }

  void _onUpdateStreamingMessage(
    UpdateStreamingMessage event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isNotEmpty) {
      final lastMessage = state.messages.last;
      if (lastMessage.role == MessageRole.assistant && lastMessage.isLoading) {
        final updatedMessage = lastMessage.copyWith(
          content: lastMessage.content + event.chunk,
          isLoading: false,
        );
        
        final updatedMessages = [
          ...state.messages.take(state.messages.length - 1),
          updatedMessage,
        ];
        
        emit(state.copyWith(messages: updatedMessages));
      }
    }
  }

  void _onClearChat(ClearChat event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: [],
      error: null,
      isLoading: false,
      isStreaming: false,
    ));
  }
}