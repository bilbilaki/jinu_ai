// lib/data/models/chat_session_item.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:uuid/uuid.dart';
import 'chat_message.dart'; // Import the ChatMessage model

// Reuse the UID instance
var _uuid = const Uuid();

class ChatSessionItem {
  String id;
  String title; // Can be first message, timestamp, or user-defined
  DateTime createdAt;
  DateTime lastModified;
  List<ChatMessage> messages; // The core history

  ChatSessionItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    required this.messages,
  });

  // --- Serialization for SharedPreferences ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    // Serialize messages carefully: Convert ChatMessage objects to JSON
    'messages': messages.map((msg) => msg.toJson()).toList(),
  };

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) {
    try {
      // Deserialize messages: Convert JSON maps back to ChatMessage objects
      List<ChatMessage> loadedMessages = [];
      if (json['messages'] is List) {
        for (var msgJson in (json['messages'] as List<dynamic>)) {
          if (msgJson is Map<String, dynamic>) {
            loadedMessages.add(ChatMessage.fromJson(msgJson));
          } else {
            debugPrint("Skipping invalid message item during ChatSessionItem deserialization: $msgJson");
          }
        }
      }

      return ChatSessionItem(
        id: json['id']?.toString() ?? _uuid.v4(), // Generate ID if missing, ensure string
        title: json['title']?.toString() ?? 'Chat Session',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        lastModified: DateTime.tryParse(json['lastModified']?.toString() ?? '') ?? DateTime.now(),
        messages: loadedMessages,
      );
    } catch (e, s) {
      debugPrint("Error deserializing ChatSessionItem: $e\nStack: $s");
      debugPrint("Problematic JSON: $json");
      // Return a default/empty item on error
      return ChatSessionItem(
          id: _uuid.v4(),
          title: 'Error Loading Chat',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          messages: [
            ChatMessage(sender: MessageSender.system, content: "Failed to load previous messages.")
          ]);
    }
  }

  // Helper to get a concise title if not set properly
  String get displayTitle {
    if (title.isNotEmpty && title != 'New Chat' && title != 'Chat Session' && title != 'Error Loading Chat') {
      return title;
    }
    if (messages.isNotEmpty) {
      final firstUserMsg = messages.firstWhere((m) => m.isUserMessage,
          orElse: () => messages.firstWhere((m) => m.content.isNotEmpty, orElse: () => messages.first));
        if (firstUserMsg.content.isNotEmpty) {
        return firstUserMsg.content.length > 40
            ? '${firstUserMsg.content.substring(0, 40)}...'
            : firstUserMsg.content;
      }
    }
    // Fallback using timestamp
    try {
      return createdAt.toLocal().toString().substring(0, 16);
    } catch (_) {
      return "Chat Session"; // Final fallback
    }
  }

   // Add copyWith method for easier updates
   ChatSessionItem copyWith({
     String? id,
     String? title,
     DateTime? createdAt,
     DateTime? lastModified,
     List<ChatMessage>? messages,
   }) {
     return ChatSessionItem(
       id: id ?? this.id,
       title: title ?? this.title,
       createdAt: createdAt ?? this.createdAt,
       lastModified: lastModified ?? this.lastModified,
       messages: messages ?? this.messages,
     );
   }
}