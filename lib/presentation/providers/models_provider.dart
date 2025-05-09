// lib/presentation/providers/models_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_openai/dart_openai.dart';
import 'settings_provider.dart'; // Need settings for API key check
// --- Provider for OpenAI Models (using SDK) ---
import 'package:google_generative_ai/google_generative_ai.dart';
final openAIModelsProvider = FutureProvider<List<OpenAIModelModel>>((ref) async {
  // Check if the MAIN API key is set in settings before trying
  // Watch specifically the token provider to avoid unnecessary rebuilds
  final settingsService = ref.watch(settingsServiceProvider);
  final apiKey = settingsService.apitokenmain;
  OpenAI.apiKey = apiKey;
  OpenAI.baseUrl = settingsService.custoombaseurl;
  OpenAI.showLogs = true;
  OpenAI.showResponsesLogs = true;

  if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
    debugPrint("Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.");
    // SDK requires key to be set globally via OpenAI.apiKey in main.dart
    // This check is mainly a safeguard / warning.
    return []; // Return empty list if key isn't properly set *in settings*
  }

  try {
    // Ensure SDK key is actually set (should be done in main.dart)
    // This call will fail if OpenAI.apiKey is not set.
    List<OpenAIModelModel> models = await OpenAI.instance.model.list();
    return models;
  } catch (e) {
    print('Error fetching OpenAI models via SDK: $e');
    // Consider logging the error more formally
    return []; // Return empty list on error
  }
});

// Provider to get just the OpenAI model IDs (strings) for dropdowns
final openAIModelIdsProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(openAIModelsProvider).whenData((models) {
     final ids = models.map((m) => m.id).toList();
     ids.sort(); // Sort alphabetically
     return ids;
  });
});


// --- Provider for Custom URL Models (from Settings Service) ---
// This uses the derived provider from `settings_provider.dart` directly.
// No need to redefine, just use `customAvailableModelsProvider`.


// --- Combined Models Logic (Optional) ---
// You might want a provider that merges models from both sources,
// or selects which list to use based on a setting.

enum ModelSource { openAI, customUrl, geminitoken }

// Example: Provider to select the source based on a hypothetical setting
// final activeModelSourceProvider = StateProvider<ModelSource>((ref) => ModelSource.openAI);

// Example: Provider that returns the appropriate model list based on the source
final currentModelListProvider = Provider<AsyncValue<List<String>>>((ref) {
    // // Example: Read a setting to determine source
    // final source = ref.watch(activeModelSourceProvider);
    // if (source == ModelSource.customUrl){
    //     final customModels = ref.watch(customAvailableModelsProvider);
    //     return AsyncData(customModels); // Wrap in AsyncData for consistent return type
    // } else {
    //     return ref.watch(openAIModelIdsProvider);
    // }

    // For now, let's default to showing the custom URL models IF available, otherwise OpenAI models
    final customModels = ref.watch(customAvailableModelsProvider);
    if (customModels.isNotEmpty) {
        return AsyncData(customModels);
    } else {
        // Fallback to OpenAI SDK models
        return ref.watch(openAIModelIdsProvider);
    }
});
Future <void> geminiModelslist()  async{
final geminiModellistProvider = FutureProvider<List<OpenAIModelModel>>((ref) async {
  // Check if the MAIN API key is set in settings before trying
  // Watch specifically the token provider to avoid unnecessary rebuilds
  final settingsService = ref.watch(settingsServiceProvider);
  final apiKey = settingsService.geminitoken;
  OpenAI.baseUrl = "https://generativelanguage.googleapis.com/v1beta/openai";
  OpenAI.showLogs = true;
  OpenAI.showResponsesLogs = true;
if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
    debugPrint("Warning: Gemini API Key not set (or is placeholder). Cannot fetch Gemini models via SDK.");
    // SDK requires key to be set globally via OpenAI.apiKey in main.dart
    // This check is mainly a safeguard / warning.
    return []; // Return empty list if key isn't properly set *in settings*
  }
// final model = GenerativeModel(
//   model: 'gemini-1.5-flash',
//   apiKey: apiKey,
// );
  try {
    // Ensure SDK key is actually set (should be done in main.dart)
    // This call will fail if OpenAI.apiKey is not set.
    List<OpenAIModelModel> models = await OpenAI.instance.model.list();
    return models;
  } catch (e) {
    debugPrint('Error fetching Gemini models via SDK: $e');
    // Consider logging the error more formally
    return []; // Return empty list on error
  }
});

// Provider to get just the OpenAI model IDs (strings) for dropdowns
final geminiModelIdsProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(geminiModellistProvider).whenData((models) {
     final ids = models.map((m) => m.id).toList();
     ids.sort(); // Sort alphabetically
     return ids;
  });
});


// --- Provider for Custom URL Models (from Settings Service) ---
// This uses the derived provider from `settings_provider.dart` directly.
// No need to redefine, just use `customAvailableModelsProvider`.


// --- Combined Models Logic (Optional) ---
// You might want a provider that merges models from both sources,
// or selects which list to use based on a setting.

// Example: Provider to select the source based on a hypothetical setting
// final activeModelSourceProvider = StateProvider<ModelSource>((ref) => ModelSource.openAI);

// Example: Provider that returns the appropriate model list based on the source
// final geminiModellistsubProvider = Provider<AsyncValue<List<String>>>((ref) {
//     // // Example: Read a setting to determine source
//     // final source = ref.watch(activeModelSourceProvider);
//     // if (source == ModelSource.customUrl){
//     //     final customModels = ref.watch(customAvailableModelsProvider);
//     //     return AsyncData(customModels); // Wrap in AsyncData for consistent return type
//     // } else {
//     //     return ref.watch(openAIModelIdsProvider);
//     // }

//     // For now, let's default to showing the custom URL models IF available, otherwise OpenAI models
//     final customModels = ref.watch(geminiModellistsubProvider);
//     if (customModels.isNotEmpty) {
//         return AsyncData(customModels);
//     } else {
//         // Fallback to OpenAI SDK models
//         return ref.watch(geminiModellistProvider);
    }
