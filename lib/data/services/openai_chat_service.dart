// lib/data/services/openai_chat_service.dart
import 'dart:convert';
import 'dart:io'; // Keep for audio/image file handling if needed
import 'package:dart_openai/dart_openai.dart'; // Make sure this is configured
import 'package:flutter/foundation.dart';
import 'package:jinu/data/models/memory_item.dart';
import 'package:jinu/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jinu/data/services/long_term_memory_service.dart';
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
  }) async {
    final settings = ref.read(settingsServiceProvider);
    _configureOpenAI(); // Refresh SDK config just in case

    bool hasImage = messages.any(
      (m) =>
          m.contentType == ContentType.image &&
          m.filePath != null &&
          m.filePath!.isNotEmpty,
    );

    bool useHttpPath =
        hasImage || (webSearchOptions != null && webSearchOptions.isNotEmpty);

    // Determine API URL for HTTP calls
    // Your new code uses 'https://api.openai.com/v1/chat/completions'
    // Allow override from settings.custoombaseurl if it's a full chat completions URL
    String httpApiUrl = 'https://api.openai.com/v1/chat/completions'; // Default
    if (settings.custoombaseurl.isNotEmpty &&
        settings.custoombaseurl.startsWith('http')) {
      // If custoombaseurl is just the base (e.g. https://api.custom.com) append /v1/chat/completions
      // If it's already the full path, use it as is.
      if (settings.custoombaseurl.endsWith('/v1/chat/completions') ||
          settings.custoombaseurl.endsWith('/chat/completions')) {
        httpApiUrl = settings.custoombaseurl;
      } else {
        // Append standard path if custom base URL doesn't look like a full chat endpoint
        httpApiUrl =
            '${settings.custoombaseurl.replaceAll(RegExp(r'/$'), '')}/v1/chat/completions';
      }
    }
    debugPrint("Chat Completion API URL for HTTP: $httpApiUrl");

    if (useHttpPath) {
      // --- HTTP Path for Vision or Web Search ---
      debugPrint(
        "Using HTTP path for chat completion. HasImage: $hasImage, WebSearch: ${webSearchOptions != null}",
      );

      List<Map<String, dynamic>> httpMessages = [];
      for (final message in messages) {
        String role;
        // Use OpenAI role if available, otherwise map from sender
        if (message.openAIRole != null) {
          role = message.openAIRole!.name;
        } else {
          switch (message.sender) {
            case MessageSender.user:
              role = "user";
              break;
            case MessageSender.ai:
              role = "assistant";
              break;
            case MessageSender.system:
              role = "system";
              break;
          }
        }

        if (message.contentType == ContentType.image &&
            message.filePath != null &&
            message.filePath!.isNotEmpty) {
          File imageFile = File(message.filePath!);
          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();
            final base64Image = base64Encode(bytes);
            String? mimeType = lookupMimeType(message.filePath!);
            mimeType ??= 'image/jpeg'; // Default if lookup fails

            List<Map<String, dynamic>> contentParts = [];
            // Vision models usually expect text before image if both are present for a single message part
            if (message.content.isNotEmpty) {
              contentParts.add({"type": "text", "text": message.content});
            }
            contentParts.add({
              "type": "image_url",
              "image_url": {"url": "data:$mimeType;base64,$base64Image"},
            });
            httpMessages.add({"role": role, "content": contentParts});
          } else {
            // If image file not found, send only text content if available
            debugPrint(
              "Image file not found: ${message.filePath}, sending text only for this message.",
            );
            if (message.content.isNotEmpty) {
              httpMessages.add({"role": role, "content": message.content});
            } else {
              // Or a placeholder if text is also empty
              httpMessages.add({
                "role": role,
                "content":
                    "[Image not found: ${message.fileName ?? 'unknown'}]",
              });
            }
          }
        } else {
          // Text-only message part
          if (message.content.isNotEmpty) {
            // Ensure content is not empty
            httpMessages.add({"role": role, "content": message.content});
          }
        }
      }

      if (httpMessages.isEmpty) {
        throw Exception("Cannot send HTTP request with no prepared messages.");
      }

      final requestBody = <String, dynamic>{
        "model": model,
        "messages": httpMessages,
        // if (maxTokens != null && maxTokens > 0) "max_tokens": maxTokens,
        //"temperature": temperature, // OpenAI API typically requires temperature
        // if (topP != null) "top_p": topP,
        // "n": 1, // Usually default
      };

      if (webSearchOptions != null && webSearchOptions.isNotEmpty) {
        // The new code snippet directly adds 'web_search_options' at the root of the JSON body
        requestBody.addAll(webSearchOptions);
      }

      debugPrint("--- Sending to OpenAI via HTTP ---");
      debugPrint("Model: $model");
      debugPrint("Temperature: $temperature");
      debugPrint("MaxTokens: $maxTokens");
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
        debugPrint("HTTP Response Body: $responseBody");

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(responseBody);
          // IMPORTANT: Adapt the HTTP response to OpenAIChatCompletionModel
          // Assuming the HTTP response structure is compatible with OpenAIChatCompletionModel.fromMap
          return OpenAIChatCompletionModel.fromMap(data);
        } else {
          String errorMsg = "API Error (${response.statusCode})";
          try {
            final Map<String, dynamic> errJson = jsonDecode(responseBody);
            if (errJson['error'] != null &&
                errJson['error']['message'] != null) {
              errorMsg = errJson['error']['message'];
            } else {
              errorMsg = responseBody;
            }
          } catch (_) {
            errorMsg = responseBody;
          }

          if (response.statusCode == 401) {
            throw Exception(
              "OpenAI API Key Invalid or Expired (HTTP). $errorMsg",
            );
          }
          if (response.statusCode == 429) {
            throw Exception("OpenAI Rate Limit Exceeded (HTTP). $errorMsg");
          }
          if (response.statusCode == 400) {
            if (errorMsg.toLowerCase().contains("image")) {
              throw Exception(
                "Model may not support images, or image data is invalid (HTTP). Error: $errorMsg",
              );
            }
          }
          throw Exception(
            "OpenAI API Error (HTTP ${response.statusCode}): $errorMsg",
          );
        }
      } catch (e) {
        debugPrint("Error during HTTP Chat Completion: $e");
        rethrow;
      }
    } else {
      // --- SDK Path for Text-Only Chat ---
      debugPrint("Using SDK path for text-only chat completion.");
    }
    // Convert our ChatMessage list to OpenAI's format
    final List<OpenAIChatCompletionChoiceMessageModel> openAIMessages = [];
    for (final message in messages) {
      final converted = convertToOpenAIMessage(
        message,
      ); // Make helper async for file reading
      openAIMessages.add(converted);
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
        model: model,
        messages: openAIMessages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
        tools: enableMemoryTools ? memoryTools : null, // Include tools here
        toolChoice:
            enableMemoryTools
                ? 'auto'
                : null, // Let AI decide when to use tools
        n: 1,
      );
    } on RequestFailedException catch (e) {
      debugPrint(
        "OpenAI API Request Failed: ${e.message} (Status Code: ${e.statusCode})",
      );
      if (e.statusCode == 401) {
        throw Exception(
          "OpenAI API Key Invalid or Expired. Please check settings.",
        );
      }
      if (e.statusCode == 429) {
        throw Exception("OpenAI Rate Limit Exceeded. Please try again later.");
      }
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

  Future<List<String>> handleToolCalls(OpenAIChatCompletionModel chatCompletion) async {
    final message = chatCompletion.choices.first.message;
    final List<String> toolResults = [];
    
    if (message.haveToolCalls) {
      for (var toolCall in message.toolCalls!) {
        try {
          switch (toolCall.function.name) {
            case 'save_to_memory':
              final result = await _handleSaveMemory(toolCall);
              toolResults.add(result);
              break;
            case 'search_memory':
              final result = await _handleSearchMemory(toolCall);
              toolResults.add(result);
              break;
            default:
              debugPrint('Unhandled tool call: ${toolCall.function.name}');
              toolResults.add('Unknown tool called: ${toolCall.function.name}');
          }
        } catch (e) {
          debugPrint('Error handling tool call ${toolCall.function.name}: $e');
          toolResults.add('Error executing ${toolCall.function.name}: ${e.toString()}');
        }
      }
    }
    
    return toolResults;
  }

  Future<String> _handleSaveMemory(OpenAIResponseToolCall toolCall) async {
    final memoryService = ref.read(longTermMemoryServiceProvider);
    final decodedArgs = jsonDecode(toolCall.function.arguments);
    
    final key = decodedArgs['key'] as String;
    final content = decodedArgs['content'] as String;
    
    debugPrint('AI is saving to memory - Key: $key, Content: $content');
    
    final result = await memoryService.saveMemoryItem(key, content);
    
    if (result['status'] == 'Success') {
      return "Successfully saved memory with key '$key'";
    } else {
      return "Failed to save memory: ${result['message']}";
    }
  }

  Future<String> _handleSearchMemory(OpenAIResponseToolCall toolCall) async {
    final memoryService = ref.read(longTermMemoryServiceProvider);
    final decodedArgs = jsonDecode(toolCall.function.arguments);
    
    final query = decodedArgs['query'] as String;
    
    debugPrint('AI is searching memory for: $query');
    
    final result = memoryService.retrieveMemoryItems(query);
    
    if (result['status'] == 'Success') {
      final memories = result['relevant_memories'] as List;
      if (memories.isEmpty) {
        return "No memories found matching '$query'";
      } else {
        return "Found ${memories.length} memories matching '$query'";
      }
    } else {
      return "Error searching memory: ${result['message']}";
    }
  }

  ///////

  // --- Text-to-Speech (TTS) using SDK ---
  Future<File?> createAudioSpeech({
    required String textContent,
    String? outputDir, // Nullable, will use temp if null
    required String filename,
    // Model and voice from your new code, make them configurable via settings
    String ttsModel = "gpt-4o-mini-tts",
    String voice = "nova", // As per your new code example "nova"
  }) async {
    _configureOpenAI(); // Ensure SDK is ready
    final settings = ref.read(settingsServiceProvider);
    // Allow override from settings if available
    final actualTtsModel =
        settings.voiceprocessingmodel.isNotEmpty
            ? settings.voiceprocessingmodel
            : ttsModel;
    final actualVoice =
        settings.setdefaultvoice.isNotEmpty ? settings.setdefaultvoice : voice;

    try {
      Directory dir;
      if (outputDir != null && outputDir.isNotEmpty) {
        dir = Directory(outputDir);
      } else {
        dir = await getTemporaryDirectory();
      }
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      File audioFile = await OpenAI.instance.audio.createSpeech(
        model: actualTtsModel,
        input: textContent,
        voice: actualVoice,
        responseFormat: OpenAIAudioSpeechResponseFormat.mp3,
        outputDirectory: dir,
        outputFileName:
            filename.endsWith('.mp3') ? filename.split('.').first : filename,
      );
      debugPrint(
        "TTS Audio created at: ${audioFile.path} using model $actualTtsModel, voice $actualVoice",
      );
      return audioFile;
    } catch (e) {
      debugPrint("Error creating TTS audio: $e");
      if (e is RequestFailedException) {
        debugPrint("TTS API Error (${e.statusCode}): ${e.message}");
      }
      return null;
    }
  }

  // --- Speech-to-Text (Transcription) using SDK ---
  Future<String?> transcribeAudioFile({
    required String filePath,
    // Model from your new code, make configurable via settings
    String transcriptionModel =
        "gpt-4o-mini-transcribe", // "gpt-4o-mini-transcribe" was in new code
  }) async {
    _configureOpenAI(); // Ensure SDK is ready
    final settings = ref.read(settingsServiceProvider);
    // Allow override from settings
    final actualTranscriptionModel = transcriptionModel;

    //   settings.voiceprocessingmodel.isNotEmpty
    //     ? settings.voiceprocessingmodel
    //   : transcriptionModel;
    //until make settings for this
    // Check if the file exists before attempting to transcribe
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint("Error: Audio file not found at $filePath for transcription.");
      return null;
    }

    try {
      OpenAIAudioModel transcription = await OpenAI.instance.audio
          .createTranscription(
            file: file,
            model: actualTranscriptionModel, // Use configured model
            responseFormat:
                OpenAIAudioResponseFormat.json, // new code uses json
          );
      debugPrint(
        "Transcription successful with model $actualTranscriptionModel: ${transcription.text}",
      );
      return transcription.text;
    } catch (e) {
      debugPrint("Error transcribing audio: $e");
      if (e is RequestFailedException) {
        debugPrint("Transcription API Error (${e.statusCode}): ${e.message}");
      }
      return null;
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
