// lib/data/services/openai_chat_service.dart
import 'dart:convert';
import 'dart:io'; // Keep for audio/image file handling if needed
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_openai/dart_openai.dart'; // Make sure this is configured
import 'package:flutter/foundation.dart';
import 'package:jinu/presentation/providers/chat_providers.dart';
import 'package:jinu/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/presentation/providers/workspace_mode_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jinu/presentation/providers/memory_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart'; // Adjust import path
import 'package:http/http.dart' as http; // Import http package
import 'package:mime/mime.dart'; // For MIME type lookup

Uuid uuid = const Uuid(); // For generating unique IDs
// NOTE: This service primarily interacts with the OpenAI SDK.
// It relies on the API key being set globally in main.dart.

class OpenAIChatService {
  final Ref ref; // Use Ref for accessing other providers

  OpenAIChatService(this.ref) {
    // Configure OpenAI SDK instance when the service is created
    _configureOpenAI();}
    // Listen for settings changes to eventually re-configure if needed (more advanced)
    // ref.listen(settingsServiceProvider, (_, settings) => _configureOpenAI(settings));
  
final isWebSearchEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isWebSearchModeEnabled;
});

final voiceOutputEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isVoiceModeEnabled;
});
final itHasImageProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isContentIncludeImageMode;
});

final itHasVoiceProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isContentIncludeVoiceMode;
});
  
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

  final List<OpenAIToolModel> memoryTools = [
    OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: 'save_to_memory',
        description:
            'Save important information to long-term memory for future reference',
        parametersSchema: {
          "type": "object",
          "properties": {
            "key": {
              "type": "string",
              "description":
                  "A short, descriptive title or topic for this memory (3-5 words)",
            },
            "content": {
              "type": "string",
              "description": "The detailed information to remember",
            },
          },
          "required": ["key", "content"],
        },
      ),
    ),
    OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: 'search_memory',
        description: 'Search long-term memory for relevant information',
        parametersSchema: {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "The search term or topic to look up in memory",
            },
          },
          "required": ["query"],
        },
      ),
    ),
  ];
  
 
  // --- Chat Completion ---
  Future<OpenAIChatCompletionModel> generateChatCompletion({
    required String model,
    required List<ChatMessage> messages, // Use our app's model
    double? temperature,
    int? maxTokens,
    //topK, // Not directly supported by OpenAI chat completion API
    double? topP,
    Map<String, dynamic>? webSearchOptions,
    // List<String>? stop, // Add if needed
    // int? seed, // Add if needed
    // Map<String, String>? responseFormat, // Add if needed
    bool enableMemoryTools = true,
  }) async {    List<ChatMessage> currentMessages = List.from(messages); // Work on a copy

    // --- Pre-process audio messages by transcribing them --
      debugPrint("Pre-processing voice messages for transcription...");
      List<ChatMessage> processedAudioMessages = [];
      for (final message in currentMessages) {
        if (message.contentType == ContentType.audio &&
            message.filePath != null &&
            message.filePath!.isNotEmpty) {
          File audioFile = File(message.filePath!);
          if (await audioFile.exists()) {
            debugPrint("Transcribing audio message: ${message.filePath}");
            try {
              final settings = ref.read(settingsServiceProvider);
              String transcriptionModel = settings.voiceprocessingmodel.isNotEmpty
                  ? settings.voiceprocessingmodel
                  : "whisper-1"; // Default whisper model

              OpenAIAudioModel transcription =
                  await OpenAI.instance.audio.createTranscription(
                file: audioFile,
                model: transcriptionModel,
                responseFormat: OpenAIAudioResponseFormat.json,
              );
              processedAudioMessages.add(ChatMessage(
                id: uuid.v4(),
                sender: message.sender, // Keep original sender
                content: transcription.text, // Transcribed text
                timestamp: DateTime.now(),
                contentType: ContentType.text, // Now it's text
                mimeType: message.id, // Link back to original audio message
              ));
              debugPrint("Transcription result: ${transcription.text}");
            } catch (e) {
              debugPrint("Error transcribing audio in pre-processing: $e");
              processedAudioMessages.add(ChatMessage(
                id: uuid.v4(),
                sender: message.sender,
                content: "[Error transcribing audio: ${message.fileName ?? 'audio file'}] - ${e.toString()}",
                timestamp: DateTime.now(),
                contentType: ContentType.text,
                mimeType: message.id,
              ));
            }
          } else {
            debugPrint("Audio file not found for pre-processing: ${message.filePath}");
            processedAudioMessages.add(ChatMessage(
              id: uuid.v4(),
              sender: message.sender,
              content: "[Audio file not found: ${message.fileName ?? 'audio file'}]",
              timestamp: DateTime.now(),
              contentType: ContentType.text,
              mimeType: message.id,
            ));
          }
        } else {
          processedAudioMessages.add(message); // Keep non-audio messages as they are
        }
      }
      currentMessages = processedAudioMessages; // Update messages list with transcriptions
  

    final settings = ref.read(settingsServiceProvider);
    bool hasImage = currentMessages.any((m) => m.contentType == ContentType.image && (m.filePath != null && m.filePath!.isNotEmpty || m.fileUrl != null && m.fileUrl!.isNotEmpty));
    bool useHttpPath = hasImage || (webSearchOptions != null && webSearchOptions.isNotEmpty);

    String httpApiUrl = '${OpenAI.baseUrl}/v1/chat/completions'; // Default
    if (settings.custoombaseurl.isNotEmpty && settings.custoombaseurl.startsWith('http')) {
      if (settings.custoombaseurl.endsWith('/v1/chat/completions') || settings.custoombaseurl.endsWith('/chat/completions')) {
        httpApiUrl = settings.custoombaseurl;
      } else {
        httpApiUrl = '${settings.custoombaseurl.replaceAll(RegExp(r'/$'), '')}/v1/chat/completions';
      }
    }
    debugPrint("Chat Completion API URL for HTTP: $httpApiUrl");

    if (useHttpPath) {
      debugPrint("Using HTTP path for chat completion. HasImage: $hasImage, WebSearch: ${webSearchOptions != null}");
      List<Map<String, dynamic>> httpFormattedMessages = [];

      for (final message in currentMessages) {
        String role;
        if (message.openAIRole != null) {
          role = message.openAIRole!.name;
        } else {
          switch (message.sender) {
            case MessageSender.user: role = OpenAIChatMessageRole.user.name; break;
            case MessageSender.ai: role = OpenAIChatMessageRole.assistant.name; break;
            case MessageSender.system: role = OpenAIChatMessageRole.system.name; break;
          }
        }

        List<Map<String, dynamic>> contentParts = [];
        // Always add text part, even if it's an empty string for an image-only message
        contentParts.add({"type": "text", "text": message.content});

        if (message.contentType == ContentType.image) {
          if (message.filePath != null && message.filePath!.isNotEmpty) {
            File imageFile = File(message.filePath!);
            if (await imageFile.exists()) {
              final bytes = await imageFile.readAsBytes();
              final base64Image = base64Encode(bytes);
              String? mimeType = lookupMimeType(message.filePath!) ?? 'image/jpeg'; // Default
              contentParts.add({
                "type": "image_url",
                "image_url": {"url": "data:$mimeType;base64,$base64Image"}
              });
            } else {
              contentParts.add({"type": "text", "text": "[Image file not found: ${message.fileName}]"});
            }
          } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
             contentParts.add({
                "type": "image_url",
                "image_url": {"url": message.fileUrl}
              });
          }
        }
        httpFormattedMessages.add({"role": role, "content": contentParts});
      }

      if (httpFormattedMessages.isEmpty) {
        throw Exception("Cannot send HTTP request with no prepared messages.");
      }

      final requestBody = <String, dynamic>{
        "model": model, // Or settings.visionprocessingmodel if specific for vision
        "messages": httpFormattedMessages,
        if (maxTokens != null && maxTokens > 0) "max_tokens": maxTokens,
        if (temperature != null) "temperature": temperature,
        if (topP != null) "top_p": topP,
      };

      if (webSearchOptions != null && webSearchOptions.isNotEmpty) {
        requestBody.addAll(webSearchOptions);
      }

      debugPrint("--- Sending to OpenAI via HTTP ---");
      debugPrint("Request Body for HTTP: ${jsonEncode(requestBody)}");

      try {
        final response = await http.post(
          Uri.parse(httpApiUrl),
          headers: {
             'Authorization': 'Bearer ${settings.apitokenmain}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        final responseBody = response.body;
        debugPrint("HTTP Response Status: ${response.statusCode}");
        // debugPrint("HTTP Response Body: $responseBody"); // Can be very verbose

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          return OpenAIChatCompletionModel.fromMap(data);
        } else {
          String errorMsg = "API Error (${response.statusCode})";
          try {
            final Map<String, dynamic> errJson = jsonDecode(responseBody);
            errorMsg = errJson['error']?['message'] ?? responseBody;
          } catch (_) {
            errorMsg = responseBody;
          }
          if (response.statusCode == 401) throw Exception("OpenAI API Key Invalid or Expired (HTTP). $errorMsg");
          if (response.statusCode == 429) throw Exception("OpenAI Rate Limit Exceeded (HTTP). $errorMsg");
          if (response.statusCode == 400 && errorMsg.toLowerCase().contains("image")) {
            throw Exception("Model may not support images, or image data is invalid (HTTP). Error: $errorMsg");
          }
          throw Exception("OpenAI API Error (HTTP ${response.statusCode}): $errorMsg");
        }
      } catch (e) {
        debugPrint("Error during HTTP Chat Completion: $e");
        rethrow;
      }
    } else {
      // --- SDK Path for Text-Only Chat (or if SDK supports multimodal in future without explicit HTTP) ---
      debugPrint("Using SDK path for chat completion.");
      final List<OpenAIChatCompletionChoiceMessageModel> openAIMessages =
          currentMessages.map((msg) => convertToOpenAIMessage(msg)).toList();

      if (openAIMessages.isEmpty) {
        throw Exception("Cannot send request with no valid messages.");
      }

      debugPrint("--- Sending to OpenAI Chat via SDK ---");
      debugPrint("Model: $model");
      // ... other params logging if needed ...

      try {
        return await OpenAI.instance.chat.create(
          model: model,
          messages: openAIMessages,
          temperature: temperature,
          maxTokens: maxTokens,
          topP: topP,
          tools: enableMemoryTools ? memoryTools : null,
          toolChoice: enableMemoryTools,
          n: 1,
        );
      } on RequestFailedException catch (e) {
        debugPrint("OpenAI API Request Failed (SDK): ${e.message} (Status Code: ${e.statusCode})");
        if (e.statusCode == 401) throw Exception("OpenAI API Key Invalid or Expired (SDK). Please check settings.");
        if (e.statusCode == 429) throw Exception("OpenAI Rate Limit Exceeded (SDK). Please try again later.");
        if (e.statusCode == 400 && e.message.toLowerCase().contains("image")) {
          throw Exception("Model may not support images via SDK path, or image data is invalid (SDK). Error: ${e.message}");
        }
        throw Exception("OpenAI API Error (SDK ${e.statusCode}): ${e.message}");
      } catch (e) {
        debugPrint("Error during OpenAI Chat Completion (SDK): $e");
        rethrow;
      }
    }
  }

  Future<List<String>> handleToolCalls(OpenAIChatCompletionModel chatCompletion) async {
    final message = chatCompletion.choices.first.message;
    final List<String> toolResults = [];

    if (message.haveToolCalls && message.toolCalls != null) {
      for (var toolCall in message.toolCalls!) {
        try {
          debugPrint("Handling tool call: ${toolCall.function.name}");
          final decodedArgs = jsonDecode(toolCall.function.arguments);
          String resultMessage;

          switch (toolCall.function.name) {
            case 'save_to_memory':
              final key = decodedArgs['key'] as String?;
              final content = decodedArgs['content'] as String?;
              if (key != null && content != null) {
                resultMessage = await _handleSaveMemory(key, content);
              } else {
                resultMessage = "Error: Missing key or content for save_to_memory.";
              }
              break;
            case 'search_memory':
              final query = decodedArgs['query'] as String?;
              if (query != null) {
                resultMessage = await _handleSearchMemory(query);
              } else {
                resultMessage = "Error: Missing query for search_memory.";
              }
              break;
            default:
              debugPrint('Unhandled tool call: ${toolCall.function.name}');
              resultMessage = 'Unknown tool called: ${toolCall.function.name}';
          }
          // Construct the tool message response for OpenAI
          // For simplicity, we're just collecting results.
          // Actual implementation would add new messages to the chat history
          // with role 'tool' and content as the result, then call chat.create again.
          // This part is simplified for brevity based on the original structure.
          toolResults.add(resultMessage);

        } catch (e) {
          debugPrint('Error handling tool call ${toolCall.function.name}: $e');
          toolResults.add('Error executing ${toolCall.function.name}: ${e.toString()}');
        }
      }
    }
    return toolResults;
  }

  Future<String> _handleSaveMemory(String key, String content) async {
    final memoryService = ref.read(longTermMemoryServiceProvider);
    debugPrint('AI is saving to memory - Key: $key, Content (preview): ${content.substring(0, (content.length > 50 ? 50 : content.length))}...');
    final result = await memoryService.saveMemoryItem(key, content);
    return result['status'] == 'Success'
        ? "Successfully saved memory with key '$key'."
        : "Failed to save memory: ${result['message']}";
  }

  Future<String> _handleSearchMemory(String query) async {
    final memoryService = ref.read(longTermMemoryServiceProvider);
    debugPrint('AI is searching memory for: $query');
    final result = await memoryService.retrieveMemoryItems(query); // Assuming retrieveMemoryItems is synchronous or you await it

    if (result['status'] == 'Success') {
      final memories = result['relevant_memories'] as List?;
      if (memories == null || memories.isEmpty) {
        return "No memories found matching '$query'.";
      } else {
        // Format memories for better presentation to the AI
        String formattedMemories = memories.map((mem) => "Key: ${mem['key']}, Content: ${mem['content']}").join("\n---\n");
        return "Found ${memories.length} memories matching '$query':\n$formattedMemories";
      }
    } else {
      return "Error searching memory: ${result['message']}";
    }
  }


  Future<String?> transcribeAudioFile({
    required String filePath,
    String? transcriptionModelOverride,
  }) async {
    _configureOpenAI();
    final settings = ref.read(settingsServiceProvider);
    final actualTranscriptionModel = transcriptionModelOverride ??
        (settings.voiceprocessingmodel.isNotEmpty
            ? settings.voiceprocessingmodel
            : "whisper-1"); // Default STT model

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint("Error: Audio file not found for transcription: $filePath");
      return null;
    }
    debugPrint("Transcribing with model: $actualTranscriptionModel");
    try {
      OpenAIAudioModel transcription =
          await OpenAI.instance.audio.createTranscription(
        file: file,
        model: actualTranscriptionModel,
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      debugPrint("Transcription successful: ${transcription.text}");
      return transcription.text;
    } catch (e) {
      debugPrint("Error transcribing audio: $e");
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
        imageSize = OpenAIImageSize.size1792Horizontal;
        break; // Note: Check actual enum names in your SDK version
      case "1792x1024":
        imageSize = OpenAIImageSize.size1792Vertical;
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
        OpenAIChatCompletionChoiceMessageContentItemModel.text(message.content),
      ],
      role: role,
    );
  }
}

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
