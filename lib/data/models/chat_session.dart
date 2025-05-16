import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  // Add settings snapshot here if needed for history

  ChatSession({
    String? id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  }) : id = id ?? uuid.v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now();

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


// filepath: c:\Users\inos\android-apps\jinu\lib\data\models\chat_message.dart
class ChatMessage {
  final String content;
  final MessageSender sender;

  ChatMessage({required this.content, required this.sender});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender': sender.toString(), // Ensure sender is serializable
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] as String,
      sender: MessageSender.values.firstWhere(
        (e) => e.toString() == json['sender'],
        orElse: () => MessageSender.system,
      ),
    );
  }
}

enum MessageSender { user, system }