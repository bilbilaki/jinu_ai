// TODO Implement this library.
// lib/data/models/memory_item.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart'; // for debugPrint

var _uuid = const Uuid();

class MemoryItem {
  final String id;
  String key; // The topic/key user/model refers to
  String content; // The actual information saved
  DateTime timestamp;

  MemoryItem({
    required this.id,
    required this.key,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
      try {
       return MemoryItem(
        id: json['id']?.toString() ?? _uuid.v4(), // Assign new ID if missing, ensure string
        key: json['key']?.toString() ?? 'Untitled',
        content: json['content']?.toString() ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e, s) {
      debugPrint("Error deserializing MemoryItem: $e\nStack: $s");
      debugPrint("Problematic JSON: $json");
      // Return a default/empty item on error
      return MemoryItem(
          id: _uuid.v4(),
          key: 'Error Loading Key',
          content: 'Error loading content',
          timestamp: DateTime.now());
    }
  }
}