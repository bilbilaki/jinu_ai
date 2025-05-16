// lib/presentation/providers/chat_providers.dart
import 'dart:io';

import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/services/chat_history_service.dart';
import 'package:jinu/presentation/providers/memory_provider.dart';
import 'package:uuid/uuid.dart';
import 'api_providers.dart';
import 'history_provider.dart';
import 'settings_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session_item.dart';
// For convertToOpenAIMessage helper
// To access methods directly
// Fpr OpenAIChatCompletionChoiceMessageModel

const uuid = Uuid();

// Provider to indicate if the AI is currently processing a message
final isLoadingProvider = StateProvider<bool>((ref) => false);
final isWebSearchEnabledProvider = StateProvider<bool>(
  (ref) => false,
); // From center_content_panel
final voiceOutputEnabledProvider = StateProvider<bool>(
  (ref) => false,
); // From center_content_panel
final newTtsFileProvider = StateProvider<File?>(
  (ref) => null,
); // For UI to pick up new TTS audio


// final chatHistoryEnabledProvider = StateProvider<bool>((ref) { // Already in history_provider
// final settings = ref.watch(settingsServiceProvider);
// return settings.historychatenabled;
// });

// final chatHistoryEnabledProvider = StateProvider<bool>((ref) {
//   final settings = ref.watch(settingsServiceProvider);
//   return settings.historychatenabled;
// });
// final chatHistoryServiceProvider = Provider<ChatHistoryService>((ref) {
//   return ChatHistoryService();
// });
// --- Main Chat Controller ---
// Handles sending messages, interacting with services, and managing loading state.
// It interacts primarily with ChatHistoryService to modify chat state.

class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ChatController(this.ref)
    : super(const AsyncData(null)); // Use AsyncValue for loading/error state

  Future<void> sendMessageWithAttachment(
    ChatMessage
    userMessagePlaceholder, // Message already added to UI by center_content_panel
    File attachmentFile,
  ) async {
    // Read current toggle states for web search and voice output
    final isWebSearchEnabled = ref.read(isWebSearchEnabledProvider);
    final voiceOutputEnabled = ref.read(voiceOutputEnabledProvider);

    // Determine attachment content type (this should ideally come from userMessagePlaceholder or be detected)
    // For simplicity, let's assume userMessagePlaceholder.contentType is correctly set by caller
    ContentType attachmentContentType = userMessagePlaceholder.contentType;

    // If contentType is generic file, attempt to infer from MIME or extension if not clearly image/audio
    if (attachmentContentType == ContentType.file) {
      String? mimeType = userMessagePlaceholder.mimeType;
      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          attachmentContentType = ContentType.image;
        } else if (mimeType.startsWith('audio/')) {
          attachmentContentType = ContentType.audio;
        }
      }
    }
    debugPrint(
   "sendMessageWithAttachment: placeholder='${userMessagePlaceholder.content}', attachmentType=$attachmentContentType",
  );

  if (attachmentContentType == ContentType.image) {
   await sendMessage(
    userMessagePlaceholder
     .content, // This is the text that might accompany the image
    imageFile: attachmentFile,
    isWebSearchEnabled: isWebSearchEnabled, // Pass current state
    voiceOutputEnabled: voiceOutputEnabled, // Pass current state
   );
  } else if (attachmentContentType == ContentType.audio) {
   // The userMessagePlaceholder ([Sent Audio: xyz.mp3]) is already in history via UI
   // Now transcribe and send
   await transcribeAndSendAudio(attachmentFile);
  } else {
   // Generic file: Add to history (already done by UI), no further LLM processing here.
   debugPrint(
    "Generic file attached: ${attachmentFile.path}. Logged in history. No direct LLM processing planned for this type.",
   );
   // Simulate a successful "send" as it's logged.
   ref.read(isLoadingProvider.notifier).state = false;
   state = const AsyncData(null);
  }
 }

    // --- Core Action: Send Message ---
    Future<void> sendMessage(
      String text, {
      File? imageFile, // For sending an image with text
      required bool isWebSearchEnabled,
      required bool voiceOutputEnabled, // Renamed for clarity
    }) async {
      state = const AsyncLoading();
      ref.read(isLoadingProvider.notifier).state = true;

      final historyService = ref.read(chatHistoryServiceProvider);
      final settings = ref.read(settingsServiceProvider);
      final chatService = ref.read(openAIChatServiceProvider);
      final titleService = ref.read(titleGeneratorServiceProvider);
      final memoryService = ref.read(longTermMemoryServiceProvider);

      // 1. Get Active Chat or Start New One
      String? currentSessionId = historyService.activeChatId;
      ChatSessionItem? currentSession;
      if (currentSessionId == null) {
        debugPrint("No active session found. Starting new chat.");
        currentSession = historyService.startNewChat();
        currentSessionId = currentSession.id;
      } else {
        currentSession = historyService.getSessionById(currentSessionId);
      }
      final historyEnabled = settings.historychatenabled;
      final String modelToUse;
      if (imageFile != null) {
        // Use vision model from settings (e.g., "gpt-4o-mini")
        modelToUse =
            settings.visionprocessingmodel.isNotEmpty
                ? settings.visionprocessingmodel
                : "gpt-4o-mini";
        debugPrint("Image provided: Using vision model $modelToUse");
      } else if (isWebSearchEnabled) {
        // Use web search model from settings (e.g., "gpt-4o-mini-search-preview")
        modelToUse = "gpt-4o-mini-search-preview"; // fallback
        debugPrint("Web Search Enabled: Using web search model $modelToUse");
      } else {
        modelToUse = settings.defaultchatmodel;
        debugPrint("Standard Chat: Using model $modelToUse");
      }

      if (historyEnabled) {
        currentSession = historyService.getSessionById(currentSessionId!);
        if (currentSession == null) {
          debugPrint(
            "Active session ID $currentSessionId not found in history. Starting new chat.",
          );
          currentSession = historyService.startNewChat();
          currentSessionId = currentSession.id;
        }
      } else {
        // History is disabled - operate on a temporary in-memory session
        // For simplicity here, we'll just prevent sending if history disabled.
        // A more complex implementation would manage a temporary message list.
        debugPrint("Chat history is disabled. Cannot send message.");
        state = AsyncError("Chat history is disabled", StackTrace.current);
        ref.read(isLoadingProvider.notifier).state =
            false; // Ensure loading is off
        return;
      }

      // 2. Create User Message
      final userMessage = ChatMessage(
        sender: MessageSender.user,
        content: text,
        timestamp: DateTime.now(),
        filePath: imageFile?.path,
        contentType: imageFile != null ? ContentType.image : ContentType.text,
        fileName: imageFile?.path.split('/').last,
        // You might want to add fileSize, mimeType if ChatMessage structure supports it
      );

      // 3. Update State Immediately (Add user message to History Service)
      ref.read(isLoadingProvider.notifier).state = true;
      try {
        await historyService.addMessageToSession(currentSessionId, userMessage);
        // Get the updated session after adding the message
        currentSession = historyService.getSessionById(currentSessionId);
      } catch (e, s) {
        debugPrint("Error adding user message to session: $e\n$s");
        state = AsyncError("Failed to save user message", s);
        ref.read(isLoadingProvider.notifier).state = false;
        return;
      }

      final bool isFirstUserMessage =
          currentSession?.messages
              .where((m) => m.sender == MessageSender.user)
              .length ==
          1;
      if (settings.autotitle &&
          isFirstUserMessage &&
          historyEnabled &&
          text.isNotEmpty) {
        try {
          final generatedTitle = await titleService.generateTitle(text);
          await historyService.updateSessionTitle(
            currentSessionId,
            generatedTitle,
          );
        } catch (e) {
          debugPrint("Title generation failed: $e");
        }
      }

      // 4. Generate Title (if enabled, first message, and history enabled)
      // final bool isFirstUserMessage =
      //     currentSession?.messages
      //         .where((m) => m.sender == MessageSender.user)
      //         .length ==
      //     1;
      // if (settings.autotitle && isFirstUserMessage && historyEnabled) {
      //   try {
      //     debugPrint("Generating title for session $currentSessionId...");
      //     final generatedTitle = await titleService.generateTitle(text);
      //     await historyService.updateSessionTitle(
      //       currentSessionId,
      //       generatedTitle,
      //     );
      //     debugPrint("Title generated: $generatedTitle");
      //   } catch (e) {
      //     debugPrint("Title generation failed: $e");
      //     // Continue without blocking chat
      //   }
      // }

      // 5. Prepare API Call
      // --- Prepare Messages for API ---
      List<ChatMessage> messagesForApi = [];

      // 1. Add System Prompt (if any)
      final systemPrompt = settings.systemInstruction;
      if (systemPrompt.isNotEmpty) {
        messagesForApi.add(
          ChatMessage(
            sender: MessageSender.system,
            content: systemPrompt,
            contentType: ContentType.text,
            openAIRole: OpenAIRole.system, // Use dedicated role if possible
          ),
        );
      }

      // 2. Add Long-Term Memory Context (if enabled) - Context Augmentation Approach
      if (settings.turnofftools == false) {
        // Using 'usetools' as the toggle for memory
        try {
          // Retrieve relevant memories based on the *user's latest message*
          final memoryResult = memoryService.retrieveMemoryItems(text);
          if (memoryResult['status'] == 'Success' &&
              memoryResult['data'] != null &&
              (memoryResult['data'] as String).isNotEmpty) {
            final memoryContext = memoryResult['data'] as String;
            debugPrint("Injecting LTM context:\n$memoryContext");
            // Inject as a system message before the user's content
            messagesForApi.add(
              ChatMessage(
                sender: MessageSender.system,
                // Prepend with a clear label for the AI
                content:
                    "Relevant information from your long-term memory based on the user's query:\n---\n$memoryContext\n---",
                contentType: ContentType.text,
                openAIRole: OpenAIRole.system,
              ),
            );
          } else if (memoryResult['status'] == 'Error') {
            debugPrint("LTM retrieval error: ${memoryResult['message']}");
            // Optionally inform the user or just log it
          }
        } catch (e) {
          debugPrint("Error during LTM retrieval: $e");
          // Non-fatal, continue without memory context
        }
      }

      // 3. Add Chat History (respecting buffer)
      List<ChatMessage> historyMessages =
          currentSession!.messages; // Get all messages (incl. user's new one)
      if (settings.historybufferlength > 0 &&
          historyMessages.length > settings.historybufferlength) {
        messagesForApi.addAll(
          historyMessages.sublist(
            historyMessages.length - settings.historybufferlength,
          ),
        );
      } else if (settings.historybufferlength == 0) {
        // If buffer is 0, only send the *last user message* which is already constructed
        // Ensure we don't add history messages if buffer is 0
        // We already added the user message if history is disabled
        // Need to ensure the userMessage is included if history is enabled but buffer=0
        if (!messagesForApi.contains(userMessage)) {
          // Ensure user message is there
          messagesForApi.add(userMessage);
        }
      } else {
        messagesForApi.addAll(
          historyMessages,
        ); // Add full history if buffer > length or negative
      }
      Map<String, dynamic>? webSearchHttpOptions;
      if (isWebSearchEnabled) {
        // Structure from your new code: {'web_search_options': {...}}
        webSearchHttpOptions = {
          'web_search_options': {
            'user_location': {
              'type': 'approximate',
              'approximate': {
                'country':
                    settings.customsearchlocation.isNotEmpty
                        ? settings.customsearchlocation
                        : 'GB',
                //       'city': settings.webSearchCity.isNotEmpty ? settings.webSearchCity : 'London',
                //     'region': settings.webSearchRegion.isNotEmpty ? settings.webSearchRegion : 'London',

                //should be in the settings
              },
            },
            // Add other options like 'max_results' if your API supports them
          },
        };
      }

      // --- Call API using the Service ---
      try {
        final response = await chatService.generateChatCompletion(
          // Pass parameters from settings or determined logic
          model: modelToUse,
          messages: messagesForApi, // Pass our ChatMessage list
          temperature: settings.temperature,
          maxTokens:
              settings.maxOutputTokens > 0 ? settings.maxOutputTokens : null,
          topP: settings.topP,
          webSearchOptions: webSearchHttpOptions,
          //tools: [], // We are doing context augmentation, not tool calling for memory *yet*
        );

        // 7. Process Response and Update State
        // TODO: Handle potential tool calls from the response if implemented
        // if (response.choices.first.message.haveToolCalls) { ... }
        final List<dynamic>? annotations =
            response.choices.first.message.toMap()['annotations'];
        final List<dynamic>? reasoning =
            response.choices.first.message.toMap()['reasoning'];
        if (reasoning != null && reasoning.isNotEmpty) {
          debugPrint("Web search reasoning received: $reasoning");
        }

        if (annotations != null && annotations.isNotEmpty) {
          debugPrint("Web search annotations received: $annotations");
        }
        final aiContent =
            response.choices.first.message.content?.first.text ??
            "AI Response was empty.";
        final Map<String, dynamic> aiMetadata = {
          'model_name':
              response.choices.first.message
                  .toMap()['model'], // Use model from RESPONSE
          'finish_reason': response.choices.first.finishReason,
          'usage_prompt_tokens': response.usage.promptTokens,
          'usage_completion_tokens': response.usage.completionTokens,
          'usage_total_tokens': response.usage.totalTokens,
          'response_id': response.id, // Add response ID
        };

        aiMetadata.removeWhere(
          (key, value) => key.startsWith('usage_') && value == null,
        );
        // Use the new fromOpenAI factory method
        final aiMessage = ChatMessage.fromOpenAI({
          'role': response.choices.first.message.role.name,
          'content': aiContent,
          'metadata': aiMetadata,
        });

        // Add AI message to history (if enabled)
        if (historyEnabled) {
          await historyService.addMessageToSession(currentSessionId, aiMessage);
        } else {
          // Handle displaying AI message if history is off (e.g., temporary list)
        }

        if (ref.read(voiceOutputEnabledProvider)) {
          try {
            final ttsFileName =
                "ai_response_${DateTime.now().millisecondsSinceEpoch}";
            final ttsAudioFile = await chatService.createAudioSpeech(
              textContent: aiContent,
              filename: ttsFileName,
              // ttsModel and voice will be taken from service defaults or settings
            );
            if (ttsAudioFile != null) {
              ref.read(newTtsFileProvider.notifier).state = ttsAudioFile;
            }
          } catch (e) {
            debugPrint("Error generating TTS for AI response: $e");
          }
        }
        // Check if the response contains tool calls
        if (response.choices.first.message.haveToolCalls) {
          try {
            // Handle tool calls and get results
            final toolResults = await chatService.handleToolCalls(response);

            // Show each tool result as a chat message
            for (final toolResult in toolResults) {
              final toolMessage = ChatMessage(
                sender: MessageSender.system, // or MessageSender.ai if you prefer
                content: toolResult,
                timestamp: DateTime.now(),
                contentType: ContentType.text,
                metadata: {'tool_result': true},
              );
              if (historyEnabled) {
                await historyService.addMessageToSession(currentSessionId, toolMessage);
              }
            }

            // Optionally, generate a follow-up response with the tool results
            final toolCalls =
                response.choices.first.message.toMap()['tool_calls']
                    as List<Map<String, dynamic>>;
            final toolCallMessages =
                toolCalls
                    .map((toolCall) => ChatMessage.fromOpenAI(toolCall))
                    .toList();

            final followUpResponse = await chatService.generateChatCompletion(
              model: modelToUse,
              messages: [
                ...messagesForApi,
                ...toolCallMessages,
                ChatMessage(
                  content:
                      "The requested actions have been completed. Please confirm to the user what was done.",
                  sender: MessageSender.system,
                ),
              ],
              temperature: settings.temperature,
              maxTokens:
                  settings.maxOutputTokens > 0
                      ? settings.maxOutputTokens
                      : null,
              topP: settings.topP,
            );

            // Process the follow-up response
            final followUpContent =
                followUpResponse.choices.first.message.content?.first.text ??
                "Follow-up AI Response was empty.";
            final followUpMessage = ChatMessage.fromOpenAI({
              'role': followUpResponse.choices.first.message.role.name,
              'content': followUpContent,
              'metadata': {
                'model_name':
                    followUpResponse.choices.first.message.toMap()['model'],
                'finish_reason': followUpResponse.choices.first.finishReason,
                'response_id': followUpResponse.id,
              },
            });

            // Add follow-up message to history (if enabled)
            if (historyEnabled) {
              await historyService.addMessageToSession(
                currentSessionId,
                followUpMessage,
              );
            }
          } catch (e) {
            debugPrint(
              "Error handling tool calls or generating follow-up response: $e",
            );
          }
        }
        state = const AsyncData(null); // Signal success
      } catch (e, s) {
        debugPrint("Error sending message to AI: $e\n$s");
        String errorMsg = e.toString().replaceFirst("Exception: ", "");
        state = AsyncError("AI Error: $errorMsg", s);
        // Add error message to chat (same as before)
        if (historyEnabled) {
          final errorMessage = ChatMessage(
            sender: MessageSender.system,
            content: "Error: Failed to get response.\n$errorMsg",
            timestamp: DateTime.now(),
            metadata: {'error': true},
          );
          try {
            await historyService.addMessageToSession(
              currentSessionId,
              errorMessage,
            );
          } catch (histErr) {
            debugPrint("Failed to add error message to history: $histErr");
          }
        }
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }

    Future<void> transcribeAndSendAudio(File audioFile) async {
      // No webSearchEnabled param here, we'll use the global provider state
      final isWebSearchEnabled = ref.read(isWebSearchEnabledProvider);
      final voiceOutputEnabled = ref.read(voiceOutputEnabledProvider);
      state = const AsyncLoading();
      ref.read(isLoadingProvider.notifier).state = true;
      final historyService = ref.read(chatHistoryServiceProvider);
      final settings = ref.read(settingsServiceProvider);
      final chatService = ref.read(openAIChatServiceProvider);
      String? currentSessionId = historyService.activeChatId;

      try {
        // 1. Add a placeholder message for the audio being processed (optional but good UX)
        if (currentSessionId != null && settings.historychatenabled) {
          final audioPlaceholderMsg = ChatMessage(
            sender: MessageSender.user,
            content: "[Processing audio: ${audioFile.path.split('/').last}...]",
            timestamp: DateTime.now(),
            contentType:
                ContentType.audio, // Or a custom "system_processing" type
            filePath: audioFile.path,
          );
          await historyService.addMessageToSession(
            currentSessionId,
            audioPlaceholderMsg,
          );
        }

        // 2. Transcribe Audio
        // Model for transcription can be from settings e.g. "gpt-4o-mini-transcribe" or "whisper-1"
        final transcribedText = await chatService.transcribeAudioFile(
          filePath: audioFile.path,
          // transcriptionModel will be taken from service defaults or settings
        );

        if (transcribedText != null && transcribedText.isNotEmpty) {
          // 3. Send transcribed text as a new message
          // Replace the placeholder or send as a new message with the transcription
          // For simplicity, sending as new message:
          debugPrint("Transcribed text: '$transcribedText'. Sending to AI.");
          // imageFile will be null for this transcribed message
          await sendMessage(
            transcribedText,
            imageFile: null,
            isWebSearchEnabled: isWebSearchEnabled,
            voiceOutputEnabled: voiceOutputEnabled,
          );
          // sendMessage will handle loading state and AsyncData/AsyncError
        } else {
          throw Exception("Transcription failed or produced empty text.");
        }
      } catch (e, s) {
        debugPrint("Error in transcribeAndSendAudio: $e\n$s");
        String errorMsg = e.toString().replaceFirst("Exception: ", "");
        state = AsyncError("Audio Processing Error: $errorMsg", s);
        if (currentSessionId != null && settings.historychatenabled) {
          final errorMessage = ChatMessage(
            sender: MessageSender.system,
            content: "Error processing audio file: $errorMsg",
            timestamp: DateTime.now(),
            metadata: {'error': true},
          );
          try {
            await historyService.addMessageToSession(
              currentSessionId,
              errorMessage,
            );
          } catch (histErr) {
            debugPrint(
              "Failed to add audio error message to history: $histErr",
            );
          }
        }
        ref.read(isLoadingProvider.notifier).state =
            false; // Ensure loading is off on error here
      }
      // isLoadingProvider is primarily managed by the final sendMessage call or error path within it.
      // If an error occurs *before* sendMessage is called (e.g., transcription itself fails badly),
      // ensure isLoading is false.
    }

    void createNewChat() {
      final historyEnabled = ref.read(chatHistoryEnabledProvider);
      if (!historyEnabled) {
        debugPrint("Cannot create new chat: History is disabled.");
        // Optionally show a message to the user
        return;
      }
      // startNewChat handles adding to list and setting active ID
      ref.read(chatHistoryServiceProvider).startNewChat();
    }

    void selectChat(String sessionId) {
      final historyEnabled = ref.read(chatHistoryEnabledProvider);
      if (!historyEnabled) {
        debugPrint("Cannot select chat: History is disabled.");
        return;
      }
      // setActiveChatId handles checking existence and notifying
      ref.read(chatHistoryServiceProvider).setActiveChatId(sessionId);
    }

    void deleteChat(String sessionId) {
      final historyEnabled = ref.read(chatHistoryEnabledProvider);
      if (!historyEnabled) {
        debugPrint("Cannot delete chat: History is disabled.");
        return;
      }
      ref.read(chatHistoryServiceProvider).deleteChatSession(sessionId);
    }
  }

  final chatControllerProvider =
      StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
        return ChatController(ref);
      });


