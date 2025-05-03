// lib/data/services/openai_chat_service.dart
import 'dart:convert';
import 'dart:io'; // Keep for audio/image file handling if needed
import 'package:dart_openai/dart_openai.dart'; // Make sure this is configured
import 'package:flutter/material.dart'; // For debugPrint
import '../models/chat_message.dart'; // Adjust import path

// NOTE: This service primarily interacts with the OpenAI SDK.
// It relies on the API key being set globally in main.dart.

class OpenAIChatService {
  final apiKey = 'aa-b1BFjpcQHWHDgTWnpsfTGm7CwueIsSjrbl8UMD5ezCLaBPHY';

  // --- Chat Completion ---
  Future<OpenAIChatCompletionModel> generateChatCompletion({
    required String model, // Get from SettingsService
    required List<OpenAIChatCompletionChoiceMessageModel>
    messages, // Convert from List<ChatMessage>
    required double temperature, // Get from SettingsService
    int? maxTokens, // Get from SettingsService or use default
    int? topK, // Get from SettingsService
    double? topP, // Get from SettingsService
    List<String>? stop, // Get related settings if needed
    int? seed, // Add if needed
    Map<String, String>? responseFormat, // Add if needed
    List<OpenAIToolModel>? tools, // Add if needed
  }) async {
    if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
      debugPrint(
        "Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.",
      );
      // SDK requires key to be set globally via OpenAI.apiKey in main.dart
      // This check is mainly a safeguard / warning.
   // Return empty list if key isn't properly set *in settings*
    }

    debugPrint("--- Sending to OpenAI ---");
    debugPrint("Model: $model");
    debugPrint("Temperature: $temperature");
    debugPrint("TopP: $topP");
    // debugPrint("Messages: ${messages.length}"); // Avoid logging full messages

    try {
      return await OpenAI.instance.chat.create(
        model: model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP, // Add TopP
        // Add other parameters from settings as needed:
        // stop: stop,
        // seed: seed,
        // responseFormat: responseFormat,
        // tools: tools,
        n: 1, // Usually want 1 choice for chat
      );
    } on RequestFailedException catch (e) {
      debugPrint(
        "OpenAI API Request Failed: ${e.message} (Status Code: ${e.statusCode})",
      );
      // Rethrow a more specific exception or handle it based on status code
      if (e.statusCode == 401)
        throw Exception("OpenAI API Key Invalid or Expired.");
      if (e.statusCode == 429)
        throw Exception("OpenAI Rate Limit Exceeded. Please try again later.");
      // Add more specific error handling
      throw Exception("OpenAI API Error (${e.statusCode}): ${e.message}");
    } catch (e) {
      debugPrint("Error during OpenAI Chat Completion: $e");
      // Consider throwing a more specific exception or returning an error state
      rethrow; // Rethrow the original error for now
    }
  }

  // --- Other OpenAI SDK Interactions ---

  // List Models (via SDK)
  Future<List<OpenAIModelModel>> listModels() async {
    if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
      debugPrint(
        "Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.",
      );
      // SDK requires key to be set globally via OpenAI.apiKey in main.dart
      // This check is mainly a safeguard / warning.
   // Return empty list if key isn't properly set *in settings*

      return []; // Return empty list if key not set
    }
    try {
      List<OpenAIModelModel> models = await OpenAI.instance.model.list();
      return models;
    } catch (e) {
      print('Error fetching OpenAI models via SDK: $e');
      return []; // Return empty list on error
    }
  }

  // Text-to-Speech
  Future<File?> createAudio(
    String textContent,
    String outputDir,
    String filename, {
    String model = "tts-1",
    String voice = "nova",
  }) async {
if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
      debugPrint(
        "Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.",
      );
      // SDK requires key to be set globally via OpenAI.apiKey in main.dart
      // This check is mainly a safeguard / warning.
   // Return empty list if key isn't properly set *in settings*
    }
    try {
      // Ensure output directory exists
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      File audioFile = await OpenAI.instance.audio.createSpeech(
        model: model, // Use model from settings?
        input: textContent,
        voice: voice, // Use voice from settings?
        responseFormat: OpenAIAudioSpeechResponseFormat.mp3,
        outputDirectory: dir, // Pass Directory object
        outputFileName: filename, // Pass just the name
      );
      debugPrint("Audio created at: ${audioFile.path}");
      return audioFile;
    } catch (e) {
      print("Error creating audio: $e");
      return null;
    }
  }

  // Speech-to-Text (Transcription)
  Future<String?> transcribeAudio(
    String filePath, {
    String model = "whisper-1",
  }) async {
   if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
      debugPrint(
        "Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.",
      );
      // SDK requires key to be set globally via OpenAI.apiKey in main.dart
      // This check is mainly a safeguard / warning.
   // Return empty list if key isn't properly set *in settings*
    }

    try {
      OpenAIAudioModel transcription = await OpenAI.instance.audio
          .createTranscription(
            file: File(filePath), // Expects a File object
            model: model, // Use model from settings?
            responseFormat:
                OpenAIAudioResponseFormat.json, // Get structured response
          );
      debugPrint("Transcription successful.");
      return transcription.text;
    } catch (e) {
      print("Error transcribing audio: $e");
      return null;
    }
  }

  // Image Generation (DALL-E)
  Future<List<String>> createImage({
    required String prompt,
    required String model, // e.g., dall-e-3 from settings
    required String size, // e.g., 1024x1024 from settings
    required String quality, // e.g., standard from settings
    int n = 1,
  }) async {
    if (apiKey.isEmpty || apiKey == "YOUR_OPENAI_API_KEY") {
      debugPrint(
        "Warning: OpenAI API Key not set (or is placeholder). Cannot fetch OpenAI models via SDK.",
      );
      // SDK requires key to be set globally via OpenAI.apiKey in main.dart
      // This check is mainly a safeguard / warning.
   // Return empty list if key isn't properly set *in settings*
    }

    // Map string size and quality to SDK enums
    OpenAIImageSize imageSize;
    switch (size) {
      case "1024x1792":
        imageSize = OpenAIImageSize.size1792Horizontal;
        break;
      case "1792x1024":
        imageSize = OpenAIImageSize.size1792Vertical;
        break;
      case "1024x1024":
      default:
        imageSize = OpenAIImageSize.size1024;
        break; // Default
    }
    OpenAIImageQuality imageQuality =
        quality == 'hd' ? OpenAIImageQuality.hd : OpenAIImageQuality.hd;

    try {
      debugPrint("Generating image with prompt: $prompt");
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        model: model, // Pass model string
        n: n,
        size: imageSize,
        quality: imageQuality,
        responseFormat: OpenAIImageResponseFormat.url, // Get URLs
      );
      debugPrint("Image generation successful.");
      return image.data
          .map((item) => item.url ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error creating image: $e");
      return []; // Return empty list on error
    }
  }

  // --- Helper ---
  // Converts our app's ChatMessage to the OpenAI SDK's format.
  // Needs enhancement for multi-modal messages (images).
  OpenAIChatCompletionChoiceMessageModel convertToOpenAIMessage(
    ChatMessage message,
  ) {
    OpenAIChatMessageRole role;
    switch (message.sender) {
      case MessageSender.user:
        role = OpenAIChatMessageRole.user;
        break;
      case MessageSender.ai:
        role = OpenAIChatMessageRole.assistant;
        break;
      case MessageSender.system:
        role = OpenAIChatMessageRole.system;
        break;
    }

    // Basic text conversion for now
    // TOOD: Handle image content if message.contentType == ContentType.image
    // This would involve creating an OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl()
    // Requires the image URL to be in message.content for image messages.
    if (message.contentType == ContentType.image &&
        message.content.startsWith('http')) {
      return OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
            message.content,
          ),
          // You might need to add a placeholder text part if the model requires it
          // OpenAIChatCompletionChoiceMessageContentItemModel.text("Image attached."),
        ],
        role: role,
      );
    }

    // Default to text content
    return OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(message.content),
      ],
      role: role,
    );
  }
}
