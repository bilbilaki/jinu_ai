// lib/presentation/providers/api_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/openai_chat_service.dart';
import '../../data/services/title_generator_service.dart';
import 'settings_provider.dart'; // Need settings for title generator API key/model

// Provider for the raw OpenAI Chat Service
  final container = ProviderContainer();
  final settingsService = container.read(settingsServiceProvider);
  final setsettingsService = settingsServiceProvider.overrideWith((ref) => settingsService);
  final apiKey = settingsService.apitokenmain;
  final title_model = settingsService.defaultchatmodel;


final openAIChatServiceProvider = Provider<OpenAIChatService>((ref) {
  // This service relies on the global API key set in main.dart
  return OpenAIChatService(ref);
});

// Provider for the Title Generator Service
// This service needs configuration (API key, model) likely from settings
final titleGeneratorServiceProvider = Provider<TitleGeneratorService>((ref) {

  // Pass the required API key and model from settings
  // Ensure your Settings Service has appropriate getters for these.
  // Use a placeholder or a specific small model if autotitlemodel isn't set.
  final firstUserMessage = "";

  return TitleGeneratorService(firstUserMessage: firstUserMessage, title_model: title_model);
});