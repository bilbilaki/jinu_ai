import 'package:equatable/equatable.dart';

enum MessageType { text, image, audio, video }
enum MessageRole { user, assistant, system }

class Message extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isLoading;
  final String? error;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.role,
    required this.timestamp,
    this.metadata,
    this.isLoading = false,
    this.error,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageRole? role,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isLoading,
    String? error,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        type,
        role,
        timestamp,
        metadata,
        isLoading,
        error,
      ];
}