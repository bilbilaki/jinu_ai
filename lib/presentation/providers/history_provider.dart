// lib/presentation/providers/history_provider.dart
import 'package:flutter/material.dart'; // For ChangeNotifier, debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/chat_history_service.dart'; // Adjust path
import '../../data/models/chat_session_item.dart'; // Adjust path
import '../../data/models/chat_message.dart'; // Adjust path
import 'settings_provider.dart'; // To check if history is enabled

// Provider for the ChatHistoryService instance (ChangeNotifier based)
final chatHistoryServiceProvider = ChangeNotifierProvider<ChatHistoryService>((ref) {
  // Constructor handles initialization and loading from prefs
  return ChatHistoryService();
});

// Provider to get the list of chat session summaries
// Takes into account whether history is enabled in settings
final chatSessionsProvider = Provider<List<ChatSessionItem>>((ref) {
  final historyEnabled = ref.watch(chatHistoryEnabledProvider);
  if (!historyEnabled) {
    return []; // Return empty list if history is disabled
  }
  final historyService = ref.watch(chatHistoryServiceProvider);
  return historyService.chatSessions;
});

// Provider to get the ID of the currently active chat
final activeChatIdProvider = Provider<String?>((ref) {
  final historyEnabled = ref.watch(chatHistoryEnabledProvider);
   if (!historyEnabled) {
       return null; // No active chat if history disabled
   }
  final historyService = ref.watch(chatHistoryServiceProvider);
  return historyService.activeChatId;
});

// Provider to get the full ChatSessionItem object for the active chat
final activeChatSessionProvider = Provider<ChatSessionItem?>((ref) {
  final historyEnabled = ref.watch(chatHistoryEnabledProvider);
     if (!historyEnabled) {
         return null;
     }
  final sessions = ref.watch(chatSessionsProvider); // Uses the filtered list
  final activeId = ref.watch(activeChatIdProvider); // Uses the potentially null ID

  if (activeId == null) return null;

  try {
    // Find in the potentially filtered list
    return sessions.firstWhere((session) => session.id == activeId);
  } catch (_) {
    // This case should be less likely now due to synchronized checks
    debugPrint("Warning: Active chat ID $activeId seems invalid or history just got disabled.");
    // Attempt to clear invalid active ID if history is still enabled
    if (ref.read(chatHistoryEnabledProvider)) {
         Future.microtask(() => ref.read(chatHistoryServiceProvider).setActiveChatId(null));
    }
    return null;
  }
});

// Provider to get only the messages of the active chat for efficiency
final activeChatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  // This doesn't need the historyEnabled check directly,
  // as activeChatSessionProvider already handles it.
  final activeSession = ref.watch(activeChatSessionProvider);
  return activeSession?.messages ?? [];
});