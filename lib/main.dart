// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:jinu/data/services/settings_service.dart';
import 'app.dart'; // Import your main app widget
import 'presentation/providers/settings_provider.dart'; // To potentially pre-fetch settings/models

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = await SettingsService();
  late final container = ProviderContainer(
  );
  await container.read(settingsServiceProvider).loadSettings();
  OpenAI.apiKey = container.read(settingsServiceProvider).apitokenmain;
  OpenAI.baseUrl = container.read(settingsServiceProvider).custoombaseurl;
  OpenAI.showLogs = true;
  OpenAI.showResponsesLogs = true;

  // --- IMPORTANT: SECURELY CONFIGURE API KEY ---
  // Option 1 (Best): Use Environment Variables (pass via --dart-define=OPENAI_API_KEY=YOUR_KEY)
  // if (OpenAI.apiKey == "YOUR_OPENAI_API_KEY" || apiKey.isEmpty) {
  //     print("\n\n******************************************");
  //     print("WARNING: OpenAI API Key not set via environment variables!");
  //     print("Please set it using --dart-define=OPENAI_API_KEY=YOUR_KEY");
  //     print("Using placeholder key - SDK calls will likely fail.");
  //     print("******************************************\n\n");
  // }


  // Option 2: Placeholder (UNSAFE - FOR DEVELOPMENT ONLY)
  // Comment out the above and uncomment below if absolutely necessary for quick local testing
  // OpenAI.apiKey = "sk-xxxx"; // <-- !! VERY UNSAFE - Replace with your key ONLY for local test, DO NOT COMMIT !!
  // if (OpenAI.apiKey == "sk-xxxx") {
  //     print("\n\nWARNING: Using hardcoded placeholder API key. Replace for real use.\n\n");
  // }

  // --- Initialize SharedPreferences & Services (implicitly done by providers) ---
  // Riverpod will instantiate the ChangeNotifierProviders when first read,
  // and their constructors call _init() which loads SharedPreferences.

  // --- Create ProviderContainer for Pre-fetching (Optional) ---
  // You could optionally pre-fetch settings or models here before runApp,
  // but it adds complexity. Often it's fine to let them load when needed.
  // final container = ProviderContainer();
  // await container.read(settingsServiceProvider).loadSettings(); // Example pre-load
  // container.read(settingsServiceProvider).getModels(); // Start model fetch

  runApp(
    // Wrap the entire app in ProviderScope for Riverpod
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWith((ref) => settingsService),
      ],
      // If using pre-fetching container:
      // observers: [/* ... logging observers ... */],
      // parent: container, // Pass the container
      child: const AiStudioCloneApp(),
    ),
  );
}