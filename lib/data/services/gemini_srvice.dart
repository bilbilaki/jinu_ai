import 'dart:convert';
import 'dart:io';
// For Uint8List

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:http/http.dart' as http;
import 'package:jinu/core/constants.dart' as constants;
import 'package:jinu/presentation/providers/settings_provider.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Assuming your ChatMessage and related enums are defined in:
import '../models/chat_message.dart'; // Adjust import path as necessary

// Assuming your providers are defined (replace with actual providers)
// Example:
// final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());
// final longTermMemoryServiceProvider = Provider<LongTermMemoryService>((ref) => LongTermMemoryService());
// final transcriptionServiceProvider = Provider<TranscriptionService>((ref) => TranscriptionService());
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
    
    final settings = ref.read(settingsServiceProvider);
// Placeholder for your actual settings provider and its model
// You need to adapt this to your existing SettingsProvider
class GeminiSettings {
  final String apiKey;
  final String chatModel; // e.g., "gemini-1.5-flash-latest"
  final String visionModel; // e.g., "gemini-1.5-pro-latest" or same as chatModel if it's multimodal
  final String transcriptionModel; // If you have a specific model for transcription
  final double temperature;
  final int? maxOutputTokens;
  final double? topP;
  final int? topK;
  final String systemInstruction;

  GeminiSettings({
    required this.apiKey,
    this.chatModel = "gemini-1.5-flash-latest", // Default model
    this.visionModel = "gemini-1.5-pro-latest", // Default vision capable model
    this.transcriptionModel = "default-stt", // Placeholder
    this.temperature = 0.7,
    this.maxOutputTokens,
    this.topP,
    this.topK,
    this.systemInstruction = "You are a helpful assistant.",
  });
}

// Replace with your actual settings provider
final geminiSettingsProvider = Provider<GeminiSettings>((ref) {
  // Example: Read from your existing settingsServiceProvider and adapt
  // final openAISettings = ref.watch(settingsServiceProvider);
  // return GeminiSettings(
  //   apiKey: openAISettings.geminiApiKey, // Assuming you add geminiApiKey to your settings
  //   chatModel: openAISettings.geminiChatModel,
  //   // ... other settings
  // );
  // For now, returning placeholder settings:
  debugPrint("WARNING: Using placeholder Gemini settings. Configure geminiSettingsProvider.");
  return GeminiSettings(apiKey: "YOUR_GEMINI_API_KEY");
});


// --- Gemini Service Specific Models (to mirror OpenAI's response structure) ---
const Uuid _uuid = Uuid();

class GeminiToolCallFull {
  final String id;
  final String type;
  final GeminiFunctionCallSpec function;

  GeminiToolCallFull({required this.id, this.type = "function", required this.function});

  factory GeminiToolCallFull.fromSDK(genai.FunctionCall sdkCall, String callId) {
    return GeminiToolCallFull(
      id: callId,
      function: GeminiFunctionCallSpec(
        name: sdkCall.name,
        arguments: jsonEncode(sdkCall.args), // Arguments as JSON string
      ),
    );
  }
}

class GeminiFunctionCallSpec {
  final String name;
  final String arguments; // JSON string of arguments

  GeminiFunctionCallSpec({required this.name, required this.arguments});
}

class GeminiResponseMessage {
  final String role; // 'model' (for assistant), 'tool' (for tool response content part)
  final String? content; // Text content
  final List<GeminiToolCallFull>? toolCalls;

  bool get haveToolCalls => toolCalls != null && toolCalls!.isNotEmpty;

  GeminiResponseMessage({required this.role, this.content, this.toolCalls});
}

class GeminiChatCompletionChoice {
  final GeminiResponseMessage message;
  final String? finishReason;
  final int index;

  GeminiChatCompletionChoice({required this.message, this.finishReason, this.index = 0});
}

class GeminiChatCompletionResult {
  final String id;
  final DateTime created;
  final String model;
  final List<GeminiChatCompletionChoice> choices;
  final genai.PromptFeedback? promptFeedback;
  final genai.UsageMetadata? usageMetadata;


  GeminiChatCompletionResult({
    required this.id,
    required this.created,
    required this.model,
    required this.choices,
    this.promptFeedback,
    this.usageMetadata,
  });

  factory GeminiChatCompletionResult.fromSDKResponse(
    genai.GenerateContentResponse sdkResponse,
    String modelName,
    String responseId,
  ) {
    final choicesList = <GeminiChatCompletionChoice>[];
    String? responseText = sdkResponse.text;
    List<genai.FunctionCall> sdkFunctionCalls = sdkResponse.functionCalls.toList();

    GeminiResponseMessage responseMessage;

    if (sdkFunctionCalls.isNotEmpty) {
      responseMessage = GeminiResponseMessage(
        role: 'model', // Gemini 'model' role is like OpenAI 'assistant'
        toolCalls: sdkFunctionCalls.map((fc) {
          final callId = _uuid.v4(); // Unique ID for this tool call instance
          return GeminiToolCallFull.fromSDK(fc, callId);
        }).toList(),
        // Per OpenAI pattern, content is often null if tool_calls are present.
        // Gemini might provide text alongside tool calls. We can include it or nullify.
        // Let's nullify to match OpenAI pattern strictly for the 'message.content'.
        // The original sdkResponse.text is still available if needed.
        content: null,
      );
    } else if (responseText != null) {
      responseMessage = GeminiResponseMessage(role: 'model', content: responseText);
    } else {
      responseMessage = GeminiResponseMessage(role: 'model', content: ""); // Empty if no text
    }

    String? finishReasonString;
    if (sdkResponse.candidates.isNotEmpty && sdkResponse.candidates.first.finishReason != null) {
      finishReasonString = sdkResponse.candidates.first.finishReason!.name;
      if (sdkFunctionCalls.isNotEmpty) {
        // If tool calls are present, OpenAI typically uses 'tool_calls'
        finishReasonString = 'tool_calls';
      }
    } else if (sdkFunctionCalls.isNotEmpty) {
      finishReasonString = 'tool_calls'; // Default if not specified but tools are there.
    }


    choicesList.add(GeminiChatCompletionChoice(
      message: responseMessage,
      finishReason: finishReasonString,
      index: 0,
    ));

    return GeminiChatCompletionResult(
      id: responseId,
      created: DateTime.now(),
      model: modelName,
      choices: choicesList,
      promptFeedback: sdkResponse.promptFeedback,
      usageMetadata: sdkResponse.usageMetadata,
    );
  }
}
// --- End of Gemini Service Specific Models ---


class GeminiChatService {
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
    
    final settings = ref.read(settingsServiceProvider);
  final Ref ref;
  genai.GenerativeModel? _generativeModel;
  GeminiSettings? _currentSettings;

  GeminiChatService(this.ref) {
    _initializeService();
    // Optionally listen to settings changes to re-initialize
    // ref.listen(geminiSettingsProvider, (_, newSettings) => _initializeService(settings: newSettings));
  }
  
  void _initializeService({GeminiSettings? settings}) {
    _currentSettings = settings ?? ref.read(geminiSettingsProvider);
    if (_currentSettings!.apiKey.isEmpty || _currentSettings!.apiKey == "YOUR_GEMINI_API_KEY") {
      debugPrint("Gemini Service: API Key is missing or placeholder. Service will not function.");
      _generativeModel = null;
      return;
    }

    // Tools are defined at model initialization for Gemini
    final tools = _geminiMemoryTools.isNotEmpty
        ? [genai.Tool(functionDeclarations: _geminiMemoryTools)]
        : null;

    // Safety Settings (Example: block less - adjust carefully!)
    // Refer to genai.HarmCategory and genai.HarmBlockThreshold
    final safetySettings = [
      genai.SafetySetting(genai.HarmCategory.harassment, genai.HarmBlockThreshold.none),
      genai.SafetySetting(genai.HarmCategory.hateSpeech, genai.HarmBlockThreshold.none),
      genai.SafetySetting(genai.HarmCategory.sexuallyExplicit, genai.HarmBlockThreshold.none),
      genai.SafetySetting(genai.HarmCategory.dangerousContent, genai.HarmBlockThreshold.none),
    ];

    _generativeModel = genai.GenerativeModel(
      model: _currentSettings!.chatModel, // Will be overridden if vision is needed by specific model
      apiKey: _currentSettings!.apiKey,
      generationConfig: genai.GenerationConfig(
        temperature: _currentSettings!.temperature,
        maxOutputTokens: _currentSettings!.maxOutputTokens,
        topP: _currentSettings!.topP,
        topK: _currentSettings!.topK,
      ),
      tools: tools, // Applied if enableMemoryTools is true during the call
      systemInstruction: _currentSettings!.systemInstruction.isNotEmpty
          ? genai.Content.system(_currentSettings!.systemInstruction)
          : null,
      safetySettings: safetySettings,
       toolConfig: tools != null
          ? genai.ToolConfig(
              functionCallingConfig: genai.FunctionCallingConfig(
                mode: genai.FunctionCallingMode.auto, // Or .any to force function call if possible
              ),
            )
          : null,
    );
    debugPrint("Gemini Service: Initialized with model ${_currentSettings!.chatModel}. System Instruction: '${_currentSettings!.systemInstruction}'");
  }

  // Gemini equivalent of OpenAI's memory tools
  final List<genai.FunctionDeclaration> _geminiMemoryTools = [
    genai.FunctionDeclaration(
           constants.funcSaveLtm, // Use constant
      "save_memory_tool",
      genai.Schema(
        genai.SchemaType.object,
        properties: {
          'key': genai.Schema(
            genai.SchemaType.string,
            description:
                'use this as title for the memory item, in future you will use this key to retrieve the memory item',
          ),
          'content': genai.Schema(
            genai.SchemaType.string,
            description: 'this part will be used as content for the memory item, use it to save any information you want to remember',
          ),
        },
        requiredProperties: ['key', 'content'],
      ),
    ),
    genai.FunctionDeclaration(
      constants.funcRetrieveLtm, // Use constant
      "retrieve_memory_tool",
      genai.Schema(
        genai.SchemaType.object,
        properties: {
          'query': genai.Schema(
            genai.SchemaType.string,
            description:
                'use this as key to retrieve the memory item',
          ),
        },
        requiredProperties: ['query'],
      ),
    )
  ];

  Future<ChatMessage?> _transcribeAudioChatMessage(ChatMessage audioMessage) async {
    if (audioMessage.contentType != ContentType.audio || audioMessage.filePath == null) {
      return audioMessage; // Not an audio message or no file path
    }
    debugPrint("Gemini Service: Transcribing audio message: ${audioMessage.fileName}");
    try {
      // Replace with your actual transcription service call
      // final transcriptionService = ref.read(transcriptionServiceProvider);
      // final transcriptionText = await transcriptionService.transcribe(audioMessage.filePath!, model: _currentSettings.transcriptionModel);
      // For now, using a placeholder. You MUST replace this.
      final String? transcriptionText = await transcribeAudioFile(filePath: audioMessage.filePath!);


      if (transcriptionText != null) {
        debugPrint("Gemini Service: Transcription result: $transcriptionText");
        return ChatMessage(
          id: _uuid.v4(), // New ID for the text version
          sender: audioMessage.sender,
          content: transcriptionText,
          timestamp: DateTime.now(),
          contentType: ContentType.text,
          // mimeType could store the ID of the original audio message if needed for linking
          mimeType: audioMessage.id, 
        );
      } else {
        debugPrint("Gemini Service: Transcription failed for ${audioMessage.fileName}");
        return ChatMessage(
          id: _uuid.v4(),
          sender: audioMessage.sender,
          content: "[Error transcribing audio: ${audioMessage.fileName ?? 'audio file'}]",
          timestamp: DateTime.now(),
          contentType: ContentType.text,
          mimeType: audioMessage.id,
        );
      }
    } catch (e) {
      debugPrint("Gemini Service: Error during audio transcription: $e");
      return ChatMessage(
          id: _uuid.v4(),
          sender: audioMessage.sender,
          content: "[Exception transcribing audio: ${audioMessage.fileName ?? 'audio file'}: ${e.toString()}]",
          timestamp: DateTime.now(),
          contentType: ContentType.text,
          mimeType: audioMessage.id,
        );
    }
  }

  Future<List<genai.Content>> _convertChatMessagesToGeminiContent(
    List<ChatMessage> messages, {
    bool forHistory = false,
  }) async {
    List<genai.Content> geminiContents = [];
    List<ChatMessage> processedMessages = [];

    // 1. Pre-process audio messages
    for (final message in messages) {
      if (message.contentType == ContentType.audio && message.filePath != null) {
        final transcribedMessage = await _transcribeAudioChatMessage(message);
        if (transcribedMessage != null) {
          processedMessages.add(transcribedMessage);
        } else {
          processedMessages.add(message); // Add original if transcription failed critically
        }
      } else {
        processedMessages.add(message);
      }
    }

    // 2. Convert to Gemini Content
    for (final message in processedMessages) {
      String role;
      switch (message.sender) {
        case MessageSender.user:
          role = 'user';
          break;
        case MessageSender.ai:
          role = 'model';
          break;
        case MessageSender.system:
          // System messages are handled by _generativeModel.systemInstruction for Gemini.
          // If they appear mid-conversation, they might need special handling.
          // For history, we might skip them or convert to 'user'/'model' with a prefix.
          // Let's skip for history for now, as Gemini expects user/model turns.
          if (forHistory) {
            debugPrint("Gemini Service: Skipping system message in history conversion: '${message.content}'");
            continue;
          } else {
            // If it's the *current* message and system, it's unusual for Gemini chat.
            // Default to user or model, or handle as per app logic.
             debugPrint("Gemini Service: Converting system message to 'user' for current prompt: '${message.content}'");
            role = 'user'; // Or 'model' depending on context, or throw error.
          }
          break;
      }

      List<genai.Part> parts = [];

      // Add text part (if any)
      if (message.content.isNotEmpty || message.contentType == ContentType.text) {
        // For tool_result, content is the JSON string of the tool's output.
        // This needs to be wrapped in a FunctionResponse part.
        if (message.contentType == ContentType.text.toString() && message.content.startsWith("tool_result")) {
 
            try {
                final Map<String,dynamic> toolResponseData = jsonDecode(message.content);
                 parts.add(genai.FunctionResponse(toolResponseData.result));
                 // For a tool_result message, the role in history should be 'function' (or 'tool' in OpenAI terms)
                 // Gemini's Content object for function response doesn't explicitly set role to 'function'.
                 // The history list simply alternates user/model, and when a model turn includes a FunctionCall,
                 // the next 'user' turn can be a FunctionResponse.
                 // So, if sender is 'user' and contentType is 'tool_result', it's a function response.
                 // If sender is 'ai' and contentType is 'tool_result', it's weird. Assume tool_result is from user side.
                 if(role != 'user' && role != 'model' && role != 'function'){ // Gemini roles for Content are user, model, function, system
                    // The 'function' role is for genai.Content.functionResponse()
                    // If this is a tool_result from MessageSender.user, it should be part of a 'user' role content
                    // For history, it's tricky. Let's assume a tool_result ChatMessage is a FunctionResponse that model needs.
                    // The SDK builds this: Content('function', [FunctionResponse(...)])
                    // The service should ensure this structure if rebuilding history.
                    // For simplicity, if it's from ChatMessage, let's assume it will be role: 'user', parts: [FunctionResponse]
                    // Actually, the Gemini SDK constructs Content(role: 'function', parts: [FunctionResponse(...)])
                    // when you use chat.history.add(Content.functionResponse(...))
                    // When building history from ChatMessage, we need to map correctly.
                    // Let's ensure the role is 'function' for tool_result Content.
                    role = 'function'; // This indicates it's a function response turn.
                }

            } catch(e) {
                debugPrint("Gemini Service: Could not parse tool_result content as JSON: ${message.content}. Error: $e. Sending as text.");
                parts.add(genai.TextPart("[Malformed tool result: ${message.content}]"));
            }

        } else {
             parts.add(genai.TextPart(message.content));
        }
      }

      // Add image part (if any)
      if (message.contentType == ContentType.image) {
        Uint8List? imageBytes;
        String? mimeType;

        if (message.filePath != null && message.filePath!.isNotEmpty) {
          final file = File(message.filePath!);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
            mimeType = lookupMimeType(message.filePath!);
          } else {
            debugPrint("Gemini Service: Image file not found: ${message.filePath}");
            parts.add(genai.TextPart("[Image file not found: ${message.fileName}]"));
          }
        } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(message.fileUrl!));
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
              // Try to get MIME type from headers or URL extension
              mimeType = response.headers['content-type'] ?? lookupMimeType(message.fileUrl!);
            } else {
              debugPrint("Gemini Service: Failed to download image from URL: ${message.fileUrl}");
              parts.add(genai.TextPart("[Failed to load image from URL: ${message.fileName}]"));
            }
          } catch (e) {
            debugPrint("Gemini Service: Error downloading image from URL: $e");
            parts.add(genai.TextPart("[Error loading image from URL: ${message.fileName}: $e]"));
          }
        }

        if (imageBytes != null) {
          mimeType ??= 'application/octet-stream'; // Fallback MIME type
          parts.add(genai.DataPart(mimeType, imageBytes));
          debugPrint("Gemini Service: Added image ${message.fileName ?? 'inline'} with MIME type $mimeType");
        }
      }
      
      if (parts.isNotEmpty) {
        geminiContents.add(genai.Content(role, parts));
      }
    }
    return geminiContents;
  }

  Future<GeminiChatCompletionResult> generateChatCompletion({
    required String modelName, // e.g., "gemini-1.5-flash-latest"
    required List<ChatMessage> messages,
    double? temperature, // Can override model's default
    int? maxTokens,     // Can override model's default
    double? topP,        // Can override model's default
    int? topK,          // Can override model's default
    bool enableMemoryTools = true,
    Map<String, dynamic>? webSearchOptions, // Placeholder for potential future custom tool
  }) async {
    if (_currentSettings == null || _generativeModel == null) {
      _initializeService(); // Try to re-initialize
      if (_generativeModel == null) {
        throw Exception("Gemini Service is not initialized. API Key might be missing.");
      }
    }
    
    final effectiveModelName = (messages.any((m) => m.contentType == ContentType.image) &&
                               !_currentSettings!.visionModel.contains("vision")) // Basic check
                               ? _currentSettings!.visionModel
                               : modelName.isNotEmpty ? modelName : _currentSettings!.chatModel;

    // Use a specific model instance for this call if modelName differs or vision is needed
    genai.GenerativeModel currentCallModel = _generativeModel!;
    if (effectiveModelName != _generativeModel!.model) {
       debugPrint("Gemini Service: Using specific model for this call: $effectiveModelName");
       currentCallModel = genai.GenerativeModel(
          model: settings.geminitextprocessingmodel,
          apiKey: settings.geminitoken,
       //   generationConfig: , // Inherit base config
          tools: _generativeModel!.tools,
          systemInstruction: settings.systemInstruction,
      //    safetySettings: _generativeModel!.safetySettings,
          toolConfig: _generativeModel!.toolConfig,
       );
    }


    // Prepare generation config for this specific call
    final currentGenerationConfig = genai.GenerationConfig(
      temperature: temperature ?? currentCallModel.generationConfig?.temperature,
      maxOutputTokens: maxTokens ?? currentCallModel.generationConfig?.maxOutputTokens,
      topP: topP ?? settingsServiceProvider.top_p,
      topK: topK ?? currentCallModel._generationConfig?.topK,
      // stopSequences: stop, // If needed
      // candidateCount: 1, // Gemini generally returns 1 for chat
    );

    List<genai.Content> conversationHistory = await _convertChatMessagesToGeminiContent(messages, forHistory: true);

    // For Gemini's generateContent, the entire conversation is passed.
    // The last message is implicitly the current user prompt if its role is 'user'.
    // If messages is empty, or last is not 'user', this might need adjustment.
    // For now, assume 'messages' represents the full history including the latest user prompt.

    if (conversationHistory.isEmpty) {
        throw Exception("Cannot send request with no messages after processing.");
    }

    // Handle webSearchOptions if you implement a custom tool for it
    if (webSearchOptions != null && webSearchOptions.isNotEmpty) {
        debugPrint("Gemini Service: 'webSearchOptions' provided but not implemented yet for Gemini.");
        // Here you would typically trigger a custom tool if 'web_search' is a defined tool
        // and these options are its arguments. For now, it's a no-op.
    }

    debugPrint("--- Sending to Gemini API ---");
    debugPrint("Model: ${currentCallModel.model}");
    debugPrint("History items: ${conversationHistory.length}");
    if (conversationHistory.isNotEmpty) {
      // conversationHistory.forEach((c) => debugPrint("Role: ${c.role}, Parts: ${c.parts.map((p) => p.runtimeType)}"));
    }
    
    try {
      genai.GenerateContentResponse response = await currentCallModel.generateContent(
        conversationHistory,
        generationConfig: currentGenerationConfig,
        tools: enableMemoryTools ? _geminiMemoryTools.isNotEmpty ? [genai.Tool(functionDeclarations: _geminiMemoryTools)] : null : null,
      );

      final responseId = _uuid.v4(); // Generate a unique ID for this overall response

      // Check for function calls
      if (response.functionCalls.isNotEmpty && enableMemoryTools) {
        debugPrint("Gemini Service: Received ${response.functionCalls.length} function call(s).");
        
        List<genai.Part> toolResponsesParts = [];
        for (final call in response.functionCalls) {
          final functionResponsePart = await _handleGeminiFunctionCall(call);
          if (functionResponsePart != null) {
            toolResponsesParts.add(functionResponsePart);
          }
        }

        if (toolResponsesParts.isNotEmpty) {
          // Add the original model's request for tool calls to history
          List<genai.Content> historyForNextTurn = List.from(conversationHistory);
          historyForNextTurn.add(
            genai.Content.model(
              response.candidates.first.content.parts
              // This should ideally be the raw function call parts from the model.
              // response.candidates.first.content.parts should contain the FunctionCall(s)
            )
          );
          
          // Add our tool execution results
          historyForNextTurn.add(genai.Content('function', toolResponsesParts)); // 'function' role for tool responses

          debugPrint("Gemini Service: Sending tool responses back to Gemini...");
          // Make a second call with the tool responses
          response = await currentCallModel.generateContent(
            historyForNextTurn,
            generationConfig: currentGenerationConfig,
            // Do not send tools again in this turn, model should respond to function results
          );
        }
      }
      
      return GeminiChatCompletionResult.fromSDKResponse(response, currentCallModel.model, responseId);

    } on genai.GenerativeAIException catch (e) {
      debugPrint("Gemini API Error: ${e.message}");
      // You might want to parse e.message for specific error codes if available
      // e.g., if (e.message.contains("401")) throw Exception("Gemini API Key Invalid or Expired.");
      // if (e.message.contains("429")) throw Exception("Gemini Rate Limit Exceeded.");
      throw Exception("Gemini API Error: ${e.message}");
    } catch (e) {
      debugPrint("Error during Gemini Chat Completion: $e");
      rethrow;
    }
  }

  Future<genai.FunctionResponse?> _handleGeminiFunctionCall(genai.FunctionCall call) async {
    final functionName = call.name;
    final args = call.args;
    Map<String, dynamic>? resultData;
    String? errorMessage;

    debugPrint("Gemini Service: Handling tool call: $functionName with args: $args");

    try {
      switch (functionName) {
        case 'save_to_memory':
          final key = args['key'] as String?;
          final content = args['content'] as String?;
          if (key != null && content != null) {
            // final memoryService = ref.read(longTermMemoryServiceProvider);
            // final serviceResult = await memoryService.saveMemoryItem(key, content); // Assuming this method exists
            // resultData = serviceResult; // Assuming serviceResult is a Map<String, dynamic> suitable for Gemini
            // For now, placeholder:
            debugPrint("Gemini Service (Tool): Saving memory - Key: $key, Content: $content");
            resultData = {'status': 'Success', 'message': "Memory item '$key' saved."};
          } else {
            errorMessage = "Missing key or content for save_to_memory.";
          }
          break;
        case 'search_memory':
          final query = args['query'] as String?;
          if (query != null) {
            // final memoryService = ref.read(longTermMemoryServiceProvider);
            // final serviceResult = await memoryService.retrieveMemoryItems(query);
            // resultData = serviceResult;
            debugPrint("Gemini Service (Tool): Searching memory - Query: $query");
            resultData = {'status': 'Success', 'found_items': ["Memory about '$query' 1", "Memory about '$query' 2"]};
          } else {
            errorMessage = "Missing query for search_memory.";
          }
          break;
        default:
          errorMessage = "Unknown function call: $functionName";
      }
    } catch (e) {
      errorMessage = "Error executing function $functionName: ${e.toString()}";
    }

    if (errorMessage != null) {
      debugPrint("Gemini Service: Tool call error for $functionName: $errorMessage");
      // Gemini expects a JSON serializable response for the function.
      // It's better to return an error structure the model can understand.
      resultData = {'error': errorMessage};
    }
    
    return genai.FunctionResponse(functionName, resultData ?? {'status': 'Completed with no data'});
  }

  // Standalone transcription method (if needed, e.g., for UI display before sending)
  Future<String?> transcribeAudioFile({
    required String filePath,
    String? transcriptionModelOverride, // e.g. "whisper-1" or a Gemini STT model
  }) async {
    if (_currentSettings == null) _initializeService();
    
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint("Gemini Service (Transcribe): Audio file not found: $filePath");
      return null;
    }

    final effectiveTranscriptionModel = transcriptionModelOverride ?? _currentSettings?.transcriptionModel ?? "default-stt";
    debugPrint("Gemini Service (Transcribe): Transcribing with model: $effectiveTranscriptionModel");

    // IMPORTANT: Implement your actual transcription logic here.
    // This could involve:
    // 1. Using a third-party STT service (like OpenAI Whisper via its API).
    // 2. Using a Google Cloud Speech-to-Text API.
    // 3. If Gemini offers a direct STT endpoint through this SDK in the future.
    // For now, this is a placeholder.
    if (effectiveTranscriptionModel == "placeholder-whisper-http") {
      // Example: If you were to call OpenAI Whisper API directly via HTTP
      // final openAISettings = ref.read(settingsServiceProvider); // Your OpenAI settings
      // try {
      //   var request = http.MultipartRequest('POST', Uri.parse('https://api.openai.com/v1/audio/transcriptions'));
      //   request.headers['Authorization'] = 'Bearer ${openAISettings.apitokenmain}';
      //   request.fields['model'] = 'whisper-1';
      //   request.files.add(await http.MultipartFile.fromPath('file', filePath));
      //   final response = await request.send();
      //   if (response.statusCode == 200) {
      //     final responseBody = await response.stream.bytesToString();
      //     final decoded = jsonDecode(responseBody);
      //     return decoded['text'] as String?;
      //   } else {
      //     debugPrint("Whisper API Error: ${response.statusCode} ${await response.stream.bytesToString()}");
      //     return null;
      //   }
      // } catch (e) {
      //   debugPrint("Error calling Whisper API: $e");
      //   return null;
      // }
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      debugPrint("Gemini Service (Transcribe): Placeholder transcription for $filePath");
      return "This is a placeholder transcription for the audio file ${basename(filePath)}.";

    } else {
       debugPrint("Gemini Service (Transcribe): No transcription provider configured for model '$effectiveTranscriptionModel'.");
       return "[Transcription not available for $filePath]";
    }
  }
}