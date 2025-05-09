// lib/presentation/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/settings_service.dart'; // Adjust path

// Provider for the SettingsService instance (ChangeNotifier based)
final container = ProviderContainer();
final settingsService = container.read(settingsServiceProvider);
final setsettingsService = settingsServiceProvider.overrideWith(
  (ref) => settingsService,
);

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
final topPProvider = Provider<double>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.topP;
});

// Provides Max Output Tokens setting
final maxOutputTokensProvider = Provider<int>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.maxOutputTokens;
});

// Provides System Instruction setting
final systemInstructionProvider = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.systemInstruction;
});

// Provides the auto title enabled flag
final autoTitleEnabledProvider = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.autotitle;
});

// Provides chat history enabled flag
final chatHistoryEnabledProvider = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.historychatenabled;
});
final baseUrlProvider = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.custoombaseurl;
});
final customapiBaseUrlProvider = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.customapiurl;
});

final customApiSubTokenProvider = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.apitokensub;
});
final defaultChatModel = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.defaultchatmodel;
});
final temperature = Provider<double>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.temperature;
});
final topP = Provider<double>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.topP;
});
final maxOutputTokens = Provider<int>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.maxOutputTokens;
});
final systemInstruction = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.systemInstruction;
});
final autoTitleEnabled = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.autotitle;
});
final chatHistoryEnabled = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.historychatenabled;
});
final themeMode = Provider<ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.themeMode;
});
final imageAnalysisModelDetails = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.imageanalysismodeldetails;
});
final imagegenerationmodl = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.imagegenerationmodel;
});
final imagegenerationmodldetails = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.imagegenerationquality;
});
final imagegenerationsize = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.imagegenerationsize;
});
final creditbalance = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.credits;
});
final setdefaultvoice = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.setdefaultvoice;
});
final voiceprocessingmodel = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.voiceprocessingmodel;
});
final messagebufferSize = Provider<int>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.messageBufferSize;
});
final topK = Provider<double>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.topK;
});
final usagemode = Provider<String>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.usagemode;
});
final responseFormat = Provider<Map<String, String>?>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.customoutputstyle;
});
final defaultvoice = Provider<String>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.setdefaultvoice;
});

final geminiapitoken = Provider<String>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.geminitoken;
});
final useaistudiotoken = Provider<bool>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.useaistudiotoken;
});

final geminidefaultchatmodel = Provider<String>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.geminitextprocessingmodel;
});
final geminivisionprocessingmodel = Provider<String>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.geminivisionprocessingmodel;
});
final geminivoiceprocessingmodel = Provider<String>((ref) { // Changed from Map<String, String>? to String
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.geminivoiceprocessingmodel;
});



Future<void> resetSettings() async {
  
  await settingsService.resetToDefaults();
}

Future<bool> resetSuccess() async {
  await resetSettings();
  return true;
}

// Add more derived providers as needed for specific settings used frequently
