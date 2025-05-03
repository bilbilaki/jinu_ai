// lib/data/services/long_term_memory_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kDebugMode and ChangeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart'; // Adjust path if needed
import '../models/memory_item.dart'; // Adjust path if needed

var _uuid = const Uuid();

class LongTermMemoryService with ChangeNotifier {
  SharedPreferences? _prefs;
  List<MemoryItem> _memoryItems = [];

  List<MemoryItem> get memoryItems => _memoryItems;

  LongTermMemoryService() {
    _init();
  }

  Future<void> _init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    await loadMemory();
  }

  Future<void> loadMemory() async {
    _prefs ??= await SharedPreferences.getInstance(); // Ensure initialized
    final String? memoryJson = _prefs!.getString(prefsLtmKey);
     _memoryItems = []; // Clear before loading
    if (memoryJson != null && memoryJson.isNotEmpty) { // Check not empty
      try {
        final List<dynamic> decodedList = jsonDecode(memoryJson); // Decode as dynamic list first
        _memoryItems = decodedList
            .where((item) => item is Map<String, dynamic>) // Ensure items are maps
            .map((item) => MemoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _memoryItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (e, s) {
        // Catch errors
        if (kDebugMode) {
          print("Error loading/decoding long term memory: $e");
          print("Stack trace: $s");
          print("Corrupted JSON string: $memoryJson");
        }
        _memoryItems = []; // Reset on error
        await _prefs!.remove(prefsLtmKey); // Optionally remove corrupted data
      }
    }
    notifyListeners(); // Notify after loading attempt
  }

  Future<void> _saveMemory() async {
    _prefs ??= await SharedPreferences.getInstance();
    _memoryItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final String memoryJson = jsonEncode(
      _memoryItems.map((e) => e.toJson()).toList(),
    );
    await _prefs!.setString(prefsLtmKey, memoryJson);
    // notifyListeners(); // Often called by the method using _saveMemory
  }

  Future<Map<String, Object?>> saveMemoryItem(
      String key,
      String content,
      ) async {
    if (key.isEmpty || content.isEmpty) {
      return {
        'status': 'Error',
        'message': 'Both key/topic and content are required to save memory.',
      };
    }
    // Trim input
    final trimmedKey = key.trim();
    final trimmedContent = content.trim();

    try {
      int existingIndex = _memoryItems.indexWhere(
            (item) => item.key.toLowerCase() == trimmedKey.toLowerCase(),
      );

      String userMessage;
      if (existingIndex != -1) {
        _memoryItems[existingIndex].content = trimmedContent;
        _memoryItems[existingIndex].timestamp = DateTime.now(); // Update timestamp
        userMessage =
        "Successfully updated memory item with key: '$trimmedKey'";
        if (kDebugMode) print("LTM: Updated entry for key '$trimmedKey'");
      } else {
        final newItem = MemoryItem(
          id: _uuid.v4(),
          key: trimmedKey,
          content: trimmedContent,
          timestamp: DateTime.now(),
        );
        _memoryItems.add(newItem); // Add new item
        userMessage =
        "Successfully saved new memory item with key: '$trimmedKey'";
        if (kDebugMode) print("LTM: Added new entry for key '$trimmedKey'");
      }
      await _saveMemory(); // Save the updated list
      notifyListeners(); // Notify after successful save/update
      // Return success map with data (the user message)
      return {
        'status': 'Success',
        'message': userMessage,
        'data': null, // Explicitly set data to null if not needed
      };
    } catch (e) {
      if (kDebugMode) print("Error in saveMemoryItem: $e");
      return {
        'status': 'Error',
        'message': 'An internal error occurred while saving the memory item.',
        'data': null,
        'error': e.toString(),
      };
    }
  }

  // Retrieve memory item(s) based on a key or topic query
  // Returns a formatted string for the AI, or an error message.
  Map<String, Object?> retrieveMemoryItems(String query) {
    if (query.trim().isEmpty) {
       return { 'status': 'Error', 'message': 'Query cannot be empty.'};
    }
    try {
      final normalizedQuery = query.trim().toLowerCase();
      final List<MemoryItem> foundItems =
      _memoryItems.where((item) {
        return item.key.toLowerCase().contains(normalizedQuery) ||
            item.content.toLowerCase().contains(normalizedQuery);
      }).toList();

      if (foundItems.isEmpty) {
        return {
          'status': 'Success', // It's a successful search, just no results
          'message': "No memory items found matching query: '$query'",
          'data': null,
        };
      }

      // Format results for the model
      StringBuffer buffer = StringBuffer();
      buffer.writeln(
        "Found ${foundItems.length} memory item(s) matching '$query':",
      );
      // Consider sorting found items by relevance or timestamp before displaying
      foundItems.sort((a,b)=> b.timestamp.compareTo(a.timestamp)); // Sort by most recent

      for (var i = 0; i < foundItems.length; i++) {
        final item = foundItems[i];
        buffer.writeln(
          "${i + 1}. Key: '${item.key}' (Saved: ${item.timestamp.toLocal().toString().substring(0, 16)})", // Consider DateFormat
        );
        buffer.writeln(" Content: ${item.content}");
        if (i < foundItems.length - 1) buffer.writeln(); // Add space between items
      }
      if (kDebugMode) {
        print("LTM: Retrieved ${foundItems.length} items for query '$query'");
      }

      return {
        'status': 'Success',
        'message': 'Memory items retrieved successfully.', // More concise message
        'data': buffer.toString(), // The formatted string
      };
    } catch (e) {
       if (kDebugMode) print("Error in retrieveMemoryItems: $e");
      return {
        'status': 'Error',
        'message': 'An internal error occurred while retrieving memory items.',
        'data': null,
        'error': e.toString(),
      };
    }
  }

  Future<void> addMemoryManually(String key, String content) async {
    // Reuse save logic, public method for UI calls
    await saveMemoryItem(key, content);
     // saveMemoryItem handles notify/save
  }

  Future<void> deleteMemoryItemById(String id) async {
    final int initialLength = _memoryItems.length;
    _memoryItems.removeWhere((item) => item.id == id);
    if (_memoryItems.length < initialLength) { // Check if removal happened
         await _saveMemory();
         notifyListeners(); // Notify after successful deletion
         if (kDebugMode) print("LTM: Deleted item with ID $id");
    } else {
         if (kDebugMode) print("LTM: Attempted to delete non-existent item with ID $id");
    }
  }

  Future<void> updateMemoryItem(MemoryItem updatedItem) async {
    int index = _memoryItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      // Ensure key/content are trimmed
      updatedItem.key = updatedItem.key.trim();
      updatedItem.content = updatedItem.content.trim();
      // Update timestamp on edit
      updatedItem.timestamp = DateTime.now();
      _memoryItems[index] = updatedItem;
      await _saveMemory();
      notifyListeners(); // Notify after successful update
       if (kDebugMode) print("LTM: Updated item with ID ${updatedItem.id}");
    } else {
       if (kDebugMode) print("LTM: Attempted to update non-existent item with ID ${updatedItem.id}");
    }
  }

  // Find similar memory items (kept from original)
  List<MemoryItem> findSimilarMemoryItems(String query, {int maxResults = 5}) {
       final normalizedQuery = query.trim().toLowerCase();
     if (normalizedQuery.isEmpty) return [];

    // Very simple scoring based on where the match occurs and recency.
    // Could be improved with more advanced text similarity algorithms (e.g., Levenshtein distance).
    List<MapEntry<MemoryItem, int>> scoredItems = [];
    final now = DateTime.now();

    for (var item in _memoryItems) {
      int score = 0;
      final keyLower = item.key.toLowerCase();
      final contentLower = item.content.toLowerCase();

      if (keyLower == normalizedQuery) {
        score += 100; // Strong match for exact key
      } else if (keyLower.startsWith(normalizedQuery)) {
        score += 50; // Prefix match
      } else if (keyLower.contains(normalizedQuery)) {
        score += 20; // Contains match
      }

      if (contentLower.contains(normalizedQuery)) {
        score += 10; // Lower score for content match
      }

      // Add recency bias (newer items get slightly higher score)
      // This bonus decreases the older the item is. Max bonus = 0 for items created now.
      int daysOld = now.difference(item.timestamp).inDays;
      score += (daysOld * -1).clamp(-50, 0); // Cap negative bonus

       if (score > 0) {
         scoredItems.add(MapEntry(item, score));
       }
    }

    // Sort by score descending
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    // Return top results, limited by maxResults
    return scoredItems.take(maxResults).map((e) => e.key).toList();
  }

}