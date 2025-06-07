import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.content,
    required super.type,
    required super.role,
    required super.timestamp,
    super.metadata,
    super.isLoading,
    super.error,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == 'MessageRole.${json['role']}',
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'role': role.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'isLoading': isLoading,
      'error': error,
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      content: message.content,
      type: message.type,
      role: message.role,
      timestamp: message.timestamp,
      metadata: message.metadata,
      isLoading: message.isLoading,
      error: message.error,
    );
  }

  MessageModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageRole? role,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isLoading,
    String? error,
  }) {
    return MessageModel(
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
}