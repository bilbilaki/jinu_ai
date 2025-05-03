// lib/presentation/providers/api_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/openai_chat_service.dart';
import '../../data/services/title_generator_service.dart';
import 'settings_provider.dart'; // Need settings for title generator API key/model

// Provider for the raw OpenAI Chat Service
  final container = ProviderContainer();

final openAIChatServiceProvider = Provider<OpenAIChatService>((ref) {
  // This service relies on the global API key set in main.dart
  return OpenAIChatService();
});

// Provider for the Title Generator Service
// This service needs configuration (API key, model) likely from settings
final titleGeneratorServiceProvider = Provider<TitleGeneratorService>((ref) {
  final settings = ref.watch(settingsServiceProvider);

  // Pass the required API key and model from settings
  // Ensure your Settings Service has appropriate getters for these.
  // Use a placeholder or a specific small model if autotitlemodel isn't set.
  final apiKey = settings.apitokenmain; // Or maybe apitokensub? Decide which key to use.
  final model = settings.autotitlemodel.isNotEmpty
                 ? settings.autotitlemodel
                 : 'gpt-3.5-turbo-0125'; // Fallback model

  return TitleGeneratorService(apiKey: apiKey, model: model);
});