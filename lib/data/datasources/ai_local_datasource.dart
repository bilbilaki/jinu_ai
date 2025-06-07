import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

abstract class AILocalDataSource {
  Future<List<MessageModel>> getChatHistory({String? conversationId});
  Future<void> saveChatHistory({
    required List<MessageModel> messages,
    String? conversationId,
  });
  Future<void> clearChatHistory({String? conversationId});
}

class AILocalDataSourceImpl implements AILocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String chatHistoryKey = 'chat_history';

  AILocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<MessageModel>> getChatHistory({String? conversationId}) async {
    final key = conversationId != null 
        ? '${chatHistoryKey}_$conversationId' 
        : chatHistoryKey;
    
    final jsonString = sharedPreferences.getString(key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => MessageModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> saveChatHistory({
    required List<MessageModel> messages,
    String? conversationId,
  }) async {
    final key = conversationId != null 
        ? '${chatHistoryKey}_$conversationId' 
        : chatHistoryKey;
    
    final jsonList = messages.map((message) => message.toJson()).toList();
    await sharedPreferences.setString(key, json.encode(jsonList));
  }

  @override
  Future<void> clearChatHistory({String? conversationId}) async {
    final key = conversationId != null 
        ? '${chatHistoryKey}_$conversationId' 
        : chatHistoryKey;
    
    await sharedPreferences.remove(key);
  }
}