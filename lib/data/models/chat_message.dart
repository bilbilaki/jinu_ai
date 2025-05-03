// lib/data/models/chat_message.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart'; // Keep for potential future color use

const _uuid = Uuid();

enum MessageSender { user, ai, system }
enum ContentType { text, image, audio } // Extend as needed

class ChatMessage {
  final String id;
  // Removed chatId as it's implicit within ChatSessionItem.messages
  final MessageSender sender;
  final String content; // Text, URL, or path
  final ContentType contentType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // For errors, API details, etc.
  final bool isUserMessage; // Helper

  ChatMessage({
    String? id,
    required this.sender,
    required this.content,
    this.contentType = ContentType.text,
    DateTime? timestamp,
    this.metadata,
  }) : id = id ?? _uuid.v4(),
       timestamp = timestamp ?? DateTime.now(),
       isUserMessage = sender == MessageSender.user;

  // --- Serialization ---
  Map<String, dynamic> toJson() => 
     {
    'id': id,
    'sender': sender.name.toString(), // Store enum name as string
    'content': content,
    'contentType': contentType.name, // Store enum name as string
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    };
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ChatMessage(
        id: json['id'] ?? _uuid.v4(),
        sender: MessageSender.values.firstWhere(
              (e) => e.name == json['sender'],
          orElse: () => MessageSender.system, // Default on error
        ),
        content: json['content']?.toString() ?? '', // Ensure content is string
        contentType: ContentType.values.firstWhere(
              (e) => e.name == json['contentType'],
          orElse: () => ContentType.text, // Default on error
        ),
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
    } catch (e, s) {
      debugPrint("Error deserializing ChatMessage: $e\nStack: $s");
      debugPrint("Problematic JSON: $json");
      // Return a default/error message on failure
      return ChatMessage(
        id: _uuid.v4(),
        sender: MessageSender.system,
        content: "[Error loading message: Invalid format]",
        timestamp: DateTime.now(),
        metadata: {'error': true, 'details': e.toString()},
      );
    }
  }

  // Helper getter for display
  String get text => content;
}