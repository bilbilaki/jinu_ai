// lib/presentation/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/settings_service.dart'; // Adjust path

// Provider for the SettingsService instance (ChangeNotifier based)
final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  // The SettingsService constructor calls _init() which loads preferences
  // and potentially fetches initial models if implemented there.
  return SettingsService();
});

// --- Derived Providers for Specific Settings ---
// These rebuild only when the specific value changes, potentially more efficient

// Provides the list of model IDs fetched via the custom URL in SettingsService
final customAvailableModelsProvider = Provider<List<String>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.availableModels;
});

// Provides the current ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.themeMode;
});

// Provides just the main API token
final mainApiTokenProvider = Provider<String>((ref) {
   final settingsService = ref.watch(settingsServiceProvider);
   return settingsService.apitokenmain;
});

// Provides the selected default chat model ID
final defaultChatModelProvider = Provider<String>((ref) {
   final settingsService = ref.watch(settingsServiceProvider);
   return settingsService.defaultchatmodel;
});

// Provides temperature setting
final temperatureProvider = Provider<double>((ref) {
   final settingsService = ref.watch(settingsServiceProvider);
   return settingsService.temperature;
});

// Provides TopP setting
final topPProvider = Provider<double>((ref){
    final settingsService = ref.watch(settingsServiceProvider);
    return settingsService.topP;
});

// Provides Max Output Tokens setting
final maxOutputTokensProvider = Provider<int>((ref){
   final settingsService = ref.watch(settingsServiceProvider);
   return settingsService.maxOutputTokens;
});

// Provides System Instruction setting
final systemInstructionProvider = Provider<String>((ref){
    final settingsService = ref.watch(settingsServiceProvider);
    return settingsService.systemInstruction;
});


// Provides the auto title enabled flag
final autoTitleEnabledProvider = Provider<bool>((ref){
   final settingsService = ref.watch(settingsServiceProvider);
   return settingsService.autotitle;
});

// Provides chat history enabled flag
final chatHistoryEnabledProvider = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.historychatenabled;
});


// Add more derived providers as needed for specific settings used frequently