// lib/data/services/openai_chat_service.dart
import 'dart:convert';
import 'dart:io'; // Keep for audio/image file handling if needed
import 'package:dart_openai/dart_openai.dart'; // Make sure this is configured
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:jinu/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart'; // Adjust import path

// NOTE: This service primarily interacts with the OpenAI SDK.
// It relies on the API key being set globally in main.dart.

class OpenAIChatService {
  final Ref ref; // Use Ref for accessing other providers

  OpenAIChatService(this.ref) {
    // Configure OpenAI SDK instance when the service is created
    _configureOpenAI();
    // Listen for settings changes to eventually re-configure if needed (more advanced)
    // ref.listen(settingsServiceProvider, (_, settings) => _configureOpenAI(settings));
  }

  // Helper to configure the OpenAI static instance based on settings
  void _configureOpenAI() {
    final settings = ref.read(settingsServiceProvider); // Read current settings
    if (settings.apitokenmain.isNotEmpty &&
        settings.apitokenmain != "YOUR_OPENAI_API_KEY") {
      OpenAI.apiKey = settings.apitokenmain;
      debugPrint("OpenAI Service: API Key configured.");
    } else {
      debugPrint("OpenAI Service: Warning - API Key is empty or placeholder.");
    }
    if (settings.custoombaseurl.isNotEmpty) {
      OpenAI.baseUrl = settings.custoombaseurl;
      debugPrint(
        "OpenAI Service: Custom Base URL configured: ${settings.custoombaseurl}",
      );
    } else {
      OpenAI.baseUrl = 'https://api.openai.com'; // Reset to default if empty
      debugPrint("OpenAI Service: Using default Base URL.");
    }
    // You could configure organization ID etc. here too if needed
    OpenAI.showLogs = kDebugMode; // Show SDK logs in debug mode
    OpenAI.showResponsesLogs = kDebugMode;
  }

  // --- Chat Completion ---
  Future<OpenAIChatCompletionModel> generateChatCompletion({
    required String model,
    required List<ChatMessage> messages, // Use our app's model
    required double temperature,
    int? maxTokens,
    //topK, // Not directly supported by OpenAI chat completion API
    double? topP,
    // List<String>? stop, // Add if needed
    // int? seed, // Add if needed
    // Map<String, String>? responseFormat, // Add if needed
    // List<OpenAIToolModel>? tools, // Add if needed for actual tool calling
    // String? toolChoice, // Add if needed
  }) async {
    // Convert our ChatMessage list to OpenAI's format
    final List<OpenAIChatCompletionChoiceMessageModel> openAIMessages = [];
    for (final message in messages) {
      final converted = await convertToOpenAIMessage(
        message,
      ); // Make helper async for file reading
      if (converted != null) {
        openAIMessages.add(converted);
      } else {
        debugPrint(
          "Warning: Skipping message conversion for message ID ${message.id}",
        );
      }
    }

    if (openAIMessages.isEmpty) {
      throw Exception("Cannot send request with no valid messages.");
    }

    debugPrint("--- Sending to OpenAI Chat ---");
    debugPrint("Model: $model");
    debugPrint("Temperature: $temperature");
    debugPrint("TopP: $topP");
    debugPrint("MaxTokens: $maxTokens");
    debugPrint("Converted Messages Count: ${openAIMessages.length}");
    // Avoid logging full messages here for privacy/size

    try {
      return await OpenAI.instance.chat.create(
        model: model, // Use the passed model
        messages: openAIMessages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
        // TODO: Add stop, seed, responseFormat, tools, toolChoice etc. if/when needed
        // tools: tools,
        // toolChoice: toolChoice,
        n: 1, // Usually want 1 choice for chat
      );
    } on RequestFailedException catch (e) {
      debugPrint(
        "OpenAI API Request Failed: ${e.message} (Status Code: ${e.statusCode})",
      );
      if (e.statusCode == 401)
        throw Exception(
          "OpenAI API Key Invalid or Expired. Please check settings.",
        );
      if (e.statusCode == 429)
        throw Exception("OpenAI Rate Limit Exceeded. Please try again later.");
      if (e.statusCode == 400) {
        // Bad request often means model incompatibility or bad input
        if (e.message.toLowerCase().contains("image")) {
          throw Exception(
            "Model may not support images, or image data is invalid. Error: ${e.message}",
          );
        }
      }
      // Add more specific error handling
      throw Exception("OpenAI API Error (${e.statusCode}): ${e.message}");
    } catch (e) {
      debugPrint("Error during OpenAI Chat Completion: $e");
      rethrow; // Rethrow the original error
    }
  }
  
  // --- Other OpenAI SDK Interactions ---

  // List Models (via SDK)
  // List Models (via SDK)
  Future<List<OpenAIModelModel>> listModels() async {
    // SDK should be configured by constructor/provider
    // Check if key is valid *before* calling (optional, SDK throws error anyway)

    try {
      List<OpenAIModelModel> models = await OpenAI.instance.model.list();
      models.sort((a, b) => a.id.compareTo(b.id)); // Sort alphabetically
      return models;
    } catch (e) {
      print('Error fetching OpenAI models via SDK: $e');
      // Differentiate error if it's auth vs network etc.
      if (e is RequestFailedException && e.statusCode == 401) {
        print("Authentication error listing models. Check API key.");
        // Optionally notify user
      }
      return []; // Return empty list on error
    }
  }

  // Text-to-Speech
  // Text-to-Speech
  Future<File?> createAudio(
    String textContent,
    String outputDir,
    String filename, {
    String model = "tts-1", // TODO: Get model/voice from settings?
    String voice = "alloy",
    OpenAIAudioSpeechResponseFormat responseFormat =
        OpenAIAudioSpeechResponseFormat.mp3,
  }) async {
    try {
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      File audioFile = await OpenAI.instance.audio.createSpeech(
        model: model,
        input: textContent,
        voice: voice,
        responseFormat: responseFormat,
        outputDirectory: dir,
        outputFileName: filename,
      );
      debugPrint("Audio created at: ${audioFile.path}");
      return audioFile;
    } catch (e) {
      print("Error creating audio: $e");
      if (e is RequestFailedException) {
        print("API Error (${e.statusCode}): ${e.message}");
      }
      return null;
    }
  }

  // Speech-to-Text (Transcription)
  // Speech-to-Text (Transcription)
  Future<String?> transcribeAudio(
    String filePath, {
    String model = "whisper-1", // TODO: Get model from settings?
    String? language, // Optional: ISO-639-1 language code
    String? prompt, // Optional: Context prompt
    OpenAIAudioResponseFormat responseFormat =
        OpenAIAudioResponseFormat.json, // or 'text'
    double? temperature, // Optional: 0-1
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print("Error: Audio file not found at $filePath");
      return null;
    }

    try {
      OpenAIAudioModel transcription = await OpenAI.instance.audio
          .createTranscription(
            file: file,
            model: model,
            prompt: prompt,
            responseFormat: responseFormat,
            temperature: temperature,
            language: language,
          );
      debugPrint("Transcription successful.");
      // If format is json (default), text is inside. If text, result is directly the string.
      return transcription
          .text; // Assumes responseFormat gets parsed correctly by SDK
    } catch (e) {
      print("Error transcribing audio: $e");
      if (e is RequestFailedException) {
        print("API Error (${e.statusCode}): ${e.message}");
      }
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
    String style = 'vivid', // DALL-E 3 option: vivid or natural
  }) async {
    // Map string size and quality to SDK enums
    OpenAIImageSize imageSize;
    switch (size) {
      case "1024x1792":
        imageSize = OpenAIImageSize.size1792Horizontal!;
        break; // Note: Check actual enum names in your SDK version
      case "1792x1024":
        imageSize = OpenAIImageSize.size1792Vertical!;
        break; // Note: Might be different
      case "1024x1024":
      default:
        imageSize = OpenAIImageSize.size1024;
        break;
    }
    OpenAIImageQuality imageQuality =
        quality == 'hd' ? OpenAIImageQuality.hd : OpenAIImageQuality.hd;
    OpenAIImageStyle imageStyle =
        style == 'natural' ? OpenAIImageStyle.natural : OpenAIImageStyle.vivid;

    try {
      debugPrint(
        "Generating image with prompt: $prompt, Model: $model, Size: $size, Quality: $quality, Style: $style",
      );
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        model: model, // Pass model string
        n: n,
        size: imageSize,
        quality: imageQuality,
        style: imageStyle,
        responseFormat: OpenAIImageResponseFormat.url, // Get URLs
        // TODO: Add user if needed
      );
      debugPrint(
        "Image generation successful. URLs: ${image.data.map((e) => e.url).toList()}",
      );
      return image.data
          .map((item) => item.url ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error creating image: $e");
      if (e is RequestFailedException) {
        print("API Error (${e.statusCode}): ${e.message}");
        // Handle specific errors like content policy violation
      }
      return []; // Return empty list on error
    }
  }

  // --- Helper ---
  // Converts our app's ChatMessage to the OpenAI SDK's format.
  // Needs enhancement for multi-modal messages (images).
   OpenAIChatCompletionChoiceMessageModel convertToOpenAIMessage(
      ChatMessage message,
    ) {
      // If the message already has an OpenAI role, use that for conversion
      if (message.openAIRole != null) {
        return OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              message.content,
            ),
          ],
          role: OpenAIChatMessageRole.values.firstWhere(
            (e) => e.name == message.openAIRole!.name,
            orElse: () => OpenAIChatMessageRole.user,
          ),
        );
      }

      // Fallback to original sender-based conversion
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

      return OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            message.content,
          ),
        ],
        role: role,
      );
    }}


//     // Add text content (caption or main text)
//     if (contentItems.isNotEmpty) {
//       contentItems.add(
//         OpenAIChatCompletionChoiceMessageContentItemModel.text(
//           message.content,
//         ),
//       );
//     }

//     // Add image content if applicable
//     if (message.contentType == ContentType.image && message.filePath != null) {
//       final imageFile = File(message.filePath!);
//       if (await imageFile.exists()) {
//         try {
//           final bytes = await imageFile.readAsBytes();
//           final base64Image = base64Encode(bytes);
//           // Determine MIME type (simple version based on extension)
//           String mimeType =
//               message.mimeType ?? "image/jpeg"; // Default or use stored mime
//           if (message.filePath!.toLowerCase().endsWith(".png"))
//             mimeType = "image/png";
//           // Add more types if needed (gif, webp)

//           contentItems.add(
//             OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
//               "data:$mimeType;base64,$base64Image",
//             ),
//           );
//           debugPrint(
//             "Added image content from path: ${message.filePath} as base64 data URI.",
//           );
//         } catch (e) {
//           debugPrint(
//             "Error reading or encoding image file ${message.filePath}: $e",
//           );
//           // Optionally add an error text part instead?
//           contentItems.add(
//             OpenAIChatCompletionChoiceMessageContentItemModel.text(
//               "[Error loading image: ${e.toString()}]",
//             ),
//           );
//         }
//       } else {
//         debugPrint("Image file not found at path: ${message.filePath}");
//         contentItems.add(
//           OpenAIChatCompletionChoiceMessageContentItemModel.text(
//             "[Image file not found]",
//           ),
//         );
//       }
//     } else if (message.contentType == ContentType.image &&
//         message.fileUrl != null) {
//       // If only URL is provided (less common for user uploads, maybe for AI responses)
//       contentItems.add(
//         OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
//           message.fileUrl!,
//         ),
//       );
//       debugPrint("Added image content from URL: ${message.fileUrl}");
//     }
   
// }
