// lib/presentation/widgets/center_content_panel.dart
import 'dart:async';
import 'dart:io'; // For File

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/models/chat_message.dart';
import 'package:jinu/data/models/chat_session_item.dart';
import 'package:jinu/presentation/screens/settings_page.dart'; // Keep settings
import 'package:mime/mime.dart'; // For getting MIME type
import 'package:path/path.dart' as p; // For getting basename (filename)
import 'package:uuid/uuid.dart'; // For generating message IDs
import 'package:jinu/presentation/providers/workspace_mode_provider.dart';
import '../providers/chat_providers.dart';
import '../providers/history_provider.dart';
import 'chat_message_widget.dart';
import 'dynamic_input_field.dart'; // Keep this

// --- Web Search & Voice Output Providers ---
// Instead of standalone providers, use the AppSettingsNotifier
final isWebSearchEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isWebSearchModeEnabled;
});

final voiceOutputEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appwmsProvider).isVoiceModeEnabled;
});

class CenterContentPanel extends ConsumerStatefulWidget {
  final bool isMobileLayout;
  const CenterContentPanel({super.key, required this.isMobileLayout});

  @override
  ConsumerState<CenterContentPanel> createState() => _CenterContentPanelState();
}

class _CenterContentPanelState extends ConsumerState<CenterContentPanel> {
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid(); // For generating message IDs

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom([bool jump = false, double? specificPosition]) {
    if (!mounted || !_scrollController.hasClients) return;

    // Use a small delay to ensure layout is complete, especially for jump scrolls
    // or when content might be dynamically changing height.
    Future.delayed(Duration(milliseconds: jump ? 50 : 100), () {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final viewportDimension = _scrollController.position.viewportDimension;

      // Scroll if near bottom, or if content doesn't fill viewport, or if jump is requested.
      // Increased threshold for "near bottom" to 200px.
      final bool shouldScroll = jump ||
          (maxScroll - currentScroll < 200) ||
          (_scrollController.position.extentTotal < viewportDimension);

      if (shouldScroll) {
        _scrollController.animateTo(
          specificPosition ?? _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage(String text) {
    final isWebSearchEnabled = ref.read(isWebSearchEnabledProvider);
    final voiceOutputEnabled = ref.read(voiceOutputEnabledProvider);

    ref.read(chatControllerProvider.notifier).sendMessage(
          text,
          isWebSearchEnabled: isWebSearchEnabled,
          voiceOutputEnabled: voiceOutputEnabled,
        );
    _scrollToBottom(true); // Force jump scroll on sending
  }

  Future<void> _sendFileMessage(File file, ContentType contentType) async {
    final String fileName = p.basename(file.path);
    final int fileSize = await file.length();
    final String? mimeType = lookupMimeType(file.path);

    final sessionId = ref.read(activeChatSessionProvider)?.id;
    if (sessionId == null) {
      debugPrint("Cannot send file: No active session.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No active chat session to send file.")),
        );
      }
      return;
    }

    final messageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: messageId,
      sender: MessageSender.user,
      content: contentType == ContentType.image
          ? "[User sent an image: $fileName]"
          : "[User sent a file: $fileName]",
      timestamp: DateTime.now(),
      contentType: contentType,
      filePath: file.path,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );

    //ref.read(activeChatMessagesProvider.allTransitiveDependencies)?.addMessage(userMessage);
    //_scrollToBottom(true);

    // Actual file sending logic (e.g., upload) should be in ChatController
    // For now, we assume ChatController handles this when it receives the message
    // (or create a specific method in ChatController like 'sendFileMessage')
    ref.read(chatControllerProvider.notifier).sendMessageWithAttachment(userMessage, file);
    // Or simply:
    // ref.read(chatControllerProvider.notifier).sendMessage(
    //   userMessage.content, // or a special type of message
    //   attachmentPath: file.path,
    //   attachmentType: contentType,
    // );
  }

  Future<void> _sendAudioMessage(File audioFile) async {
    final String fileName = p.basename(audioFile.path);
    final int fileSize = await audioFile.length();
    final String? mimeType = lookupMimeType(audioFile.path);

    final sessionId = ref.read(activeChatSessionProvider)?.id;
    if (sessionId == null) {
      debugPrint("Cannot send audio: No active session.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No active chat session to send audio.")),
        );
      }
      return;
    }

    final messageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: messageId,
      sender: MessageSender.user,
      content: "[User sent audio: $fileName]",
      timestamp: DateTime.now(),
      contentType: ContentType.audio,
      filePath: audioFile.path,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );

   // ref.read(activeChatMessagesProvider.notifier).addMessage(userMessage);
    _scrollToBottom(true);

    // Similar to _sendFileMessage, delegate actual processing to ChatController
    ref.read(chatControllerProvider.notifier).sendMessageWithAttachment(userMessage, audioFile);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(activeChatMessagesProvider);
    final currentSession = ref.watch(activeChatSessionProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final chatControllerState = ref.watch(chatControllerProvider);
    final isWebSearchEnabled = ref.watch(isWebSearchEnabledProvider);
    final voiceOutputEnabled = ref.watch(voiceOutputEnabledProvider);

    ref.listen<List<ChatMessage>>(activeChatMessagesProvider, (prev, next) {
      // Scroll when a new message is added, especially if it's from AI or the list was short.
      if ((prev == null || next.length > prev.length)) {
           // If the new message is likely an AI response, ensure scroll.
           // Or if we just sent a message.
        _scrollToBottom(true); // Use jump scroll for new messages
      } else {
        _scrollToBottom(); // Gentle scroll for other updates
      }
    });

    ref.listen<bool>(isLoadingProvider, (_, nextIsLoading) {
      if (nextIsLoading) {
        _scrollToBottom(true);
      } else {
        // After loading finishes, new content might have appeared.
        _scrollToBottom(true);
      }
    });

    ref.listen<ChatSessionItem?>(activeChatSessionProvider, (_, nextSession) {
      if (nextSession != null) {
        // When session changes, messages will repopulate, ensure view is at the bottom.
        _scrollToBottom(true, 0.0); // Jump to top initially, then scroll to bottom after messages load
        Future.delayed(const Duration(milliseconds: 200), () => _scrollToBottom(true));
      }
    });
    return Container(
      color: const Color(0xFF202124), // Dark background for readability
      child: Column(
        children: [
          if (!widget.isMobileLayout)
            _buildDesktopTopBar(
              context,
              currentSession?.displayTitle ?? "New Chat",
            ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobileLayout ? 12.0 : 36.0,
              vertical: 6.0,
            ),
            color: const Color(0xFF202124), // Match background
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildToggleSwitch(
                  label: 'Web Search:',
                  value: isWebSearchEnabled,
                  onChanged: isLoading
                      ? null
                      : (value) {
ref.read(appwmsProvider.notifier).toggleWebSearchMode(value);
                          debugPrint("Web Search: $value");
                        },
                ),
                const SizedBox(width: 16),
                _buildToggleSwitch(
                  label: 'Voice Mode:',
                  value: voiceOutputEnabled,
                  onChanged: isLoading
                      ? null
                      : (value) {
ref.read(appwmsProvider.notifier).toggleVoiceMode(value);
                          debugPrint("Voice Output: $value");
                        },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobileLayout ? 8.0 : 32.0, // Reduced horizontal padding
              ),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: _buildChatListOrPlaceholder(
                  context,
                  messages,
                  currentSession,
                ),
              ),
            ),
          ),
          // --- Loading Indicator and Error Display ---
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: LinearProgressIndicator(
                minHeight: 3, // Slightly thicker
                backgroundColor: Colors.transparent,
                color: Colors.blueAccent, // Brighter color for visibility
              ),
            ),
          chatControllerState.maybeWhen(
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[700]!, width: 0.5)
                ),
                child: Text(
                  "Error: $error", // Consider a more user-friendly error message
                  style: TextStyle(color: Colors.red[200], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isMobileLayout ? 10.0 : 32.0, // Reduced horizontal padding
              8.0,
              widget.isMobileLayout ? 10.0 : 32.0,
              widget.isMobileLayout ? 12.0 : 20.0, // Ensure enough bottom padding, esp. on mobile
            ),
            child: DynamicInputField(
              isLoading: isLoading,
              onSend: _sendTextMessage,
              onSendFile: _sendFileMessage,
              onSendAudio: _sendAudioMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    // final isWebSearchEnabled = ref.watch(isWebSearchEnabledProvider);
    // final voiceOutputEnabled = ref.watch(voiceOutputEnabledProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[300]), // Increased font size
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 24, // Constrain height for better alignment
          width: 40, // Explicit width for switch
          child: Transform.scale( // Make switch slightly smaller for dense UI
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged:onChanged,
              activeColor: Colors.blueAccent, // Brighter active color
              activeTrackColor: Colors.blueAccent.withOpacity(0.5),
              inactiveThumbColor: Colors.grey[500],
              inactiveTrackColor: Colors.grey[800],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), // Adjusted padding
      decoration: BoxDecoration(
        color: const Color(0xFF2a2b2f), // Slightly different shade for distinction
        border: Border(bottom: BorderSide(color: Colors.grey[850]!, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17, // Slightly larger
                fontWeight: FontWeight.w500,
                color: Colors.grey[200], // Brighter text
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildTopBarButton(
            context,
            icon: Icons.save_alt_outlined,
            tooltip: 'Save Chat (Not Implemented)',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save chat feature is not yet implemented.'), duration: Duration(seconds: 2)),
              );
            },
          ),
          const SizedBox(width: 4),
          _buildTopBarButton(
            context,
            icon: Icons.cleaning_services_outlined,
            tooltip: 'Clear Chat (Not Implemented)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clear chat feature is not yet implemented.'), duration: Duration(seconds: 2)),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildTopBarButton(
            context,
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton(BuildContext context, {required IconData icon, required String tooltip, VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 22, color: Colors.grey[400]),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildChatListOrPlaceholder(
    BuildContext context,
    List<ChatMessage> messages,
    ChatSessionItem? currentSession,
  ) {
    if (currentSession == null && messages.isEmpty) {
      return _buildGettingStartedPlaceholder(context, "No chat selected");
    } else if (messages.isEmpty && currentSession != null) {
      return _buildGettingStartedPlaceholder(context, "Send a message or file to start this chat...");
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ChatMessageWidget(key: ValueKey(message.id), message: message);
        },
      );
    }
  }

  Widget _buildGettingStartedPlaceholder(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_rounded, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              "Your conversation will appear here. Ask questions, upload files, or record audio.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension method to add messages - ensure your ChatMessageNotifier has this
extension ChatMessageNotifierExtension on StateController<List<ChatMessage>> {
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
}