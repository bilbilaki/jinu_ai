// lib/presentation/widgets/center_content_panel.dart
import 'dart:io'; // For File

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/models/chat_message.dart';
import 'package:jinu/data/models/chat_session_item.dart';
import 'package:jinu/presentation/screens/settings_page.dart'; // Keep settings
import 'package:mime/mime.dart';      // For getting MIME type
import 'package:path/path.dart' as p; // For getting basename (filename)
import 'package:uuid/uuid.dart';     // For generating message IDs

import '../providers/chat_providers.dart';
import '../providers/history_provider.dart';
import 'chat_message_widget.dart';
import 'dynamic_input_field.dart'; // Keep this

// --- Add Web Search Provider ---
final isWebSearchEnabledProvider = StateProvider<bool>((ref) => false); // Default off

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

  // Auto-scroll logic (keep your implementation)
  void _scrollToBottom([bool jump = false]) {
    // Check if mounted and controller has clients
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Simplified: Always scroll if near bottom OR jump required
    final shouldScroll = jump || (maxScroll - currentScroll < 150); // Increased threshold?

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) { // Double-check after callback
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration:const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }


  // --- Send Text Message ---
  void _sendTextMessage(String text) {
     final isWebSearchEnabled = ref.read(isWebSearchEnabledProvider);
     // TODO: Modify ChatController.sendMessage to potentially accept the webSearch flag
    ref.read(chatControllerProvider.notifier).sendMessage(text,
        isWebSearchEnabled: isWebSearchEnabled, // Pass the value
);
     _scrollToBottom(true); // Force jump scroll on sending
  }

  // --- Send File/Image Message ---
  Future<void> _sendFileMessage(File file, ContentType contentType) async {
    final String fileName = p.basename(file.path); // Get filename from path
    final int fileSize = await file.length();
    final String? mimeType = lookupMimeType(file.path);

    // Create a preliminary User message to display immediately
    final sessionId = ref.read(activeChatSessionProvider)?.id;
    if (sessionId == null) {
      debugPrint("Cannot send file: No active session.");
      // Show error to user?
      return;
    }

    final messageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: messageId,
      sender: MessageSender.user,
      // Content could be filename or empty, depending on how you want to display user's upload
      content: contentType == ContentType.image ? "[Sent Image]" : "[Sent File: $fileName]",
      timestamp: DateTime.now(),
      contentType: contentType,
      filePath: file.path, // Store local path for display
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );

    // Add the user message to the local state *immediately*
    ref.read(activeChatMessagesProvider).add(userMessage);
    _scrollToBottom(true); // Scroll down after adding user message

    // --- Call your ChatController to handle the actual upload/processing ---
    // Option 1: Upload happens in ChatController
    // ref.read(chatControllerProvider.notifier).sendFile(file, contentType);

    // Option 2: If ChatController expects structured data
    // Maybe create a different method?
    // ref.read(chatControllerProvider.notifier).sendMessageWithAttachment(userMessage);

    // Placeholder: Simulate AI response after a delay (REMOVE THIS IN REAL APP)
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (!mounted) return;
    //   final aiResponse = ChatMessage(
    //     id: _uuid.v4(),
    //     sessionId: sessionId,
    //     sender: MessageSender.ai,
    //     content: "Received your ${contentType.name}: $fileName",
    //     timestamp: DateTime.now(),
    //   );
    //   ref.read(activeChatMessagesProvider.notifier).addMessage(aiResponse);
    // });
  }

  // --- Send Audio Message ---
  Future<void> _sendAudioMessage(File audioFile) async {
    final String fileName = p.basename(audioFile.path);
    final int fileSize = await audioFile.length();
    final String? mimeType = lookupMimeType(audioFile.path);

    final sessionId = ref.read(activeChatSessionProvider)?.id;
    if (sessionId == null) {
      debugPrint("Cannot send audio: No active session.");
      return;
    }

    final messageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: messageId,
      sender: MessageSender.user,
      content: "[Sent Audio]", // Placeholder text
      timestamp: DateTime.now(),
      contentType: ContentType.audio,
      filePath: audioFile.path,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      // Optionally add duration metadata if easily available from recorder
      // metadata: {'duration': durationInMillis},
    );

    ref.read(activeChatMessagesProvider).add(userMessage);
    _scrollToBottom(true);

    // --- Call ChatController to handle audio ---
    // ref.read(chatControllerProvider.notifier).sendAudioFile(audioFile);
    // ref.read(chatControllerProvider.notifier).sendMessageWithAttachment(userMessage);

     // Placeholder AI response (REMOVE)
    // Future.delayed(const Duration(seconds: 1), () {
    //   if (!mounted) return;
    //   final aiResponse = ChatMessage(
    //     id: _uuid.v4(),
    //     sessionId: sessionId,
    //     sender: MessageSender.ai,
    //     content: "Heard the audio: $fileName",
    //     timestamp: DateTime.now(),
    //   );
    //   ref.read(activeChatMessagesProvider.notifier).addMessage(aiResponse);
    // });
  }



  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(activeChatMessagesProvider);
    final currentSession = ref.watch(activeChatSessionProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final chatControllerState = ref.watch(chatControllerProvider);
    final isWebSearchEnabled = ref.watch(isWebSearchEnabledProvider); // Watch web search state

    // Listen for message changes AND loading state changes to scroll
    ref.listen(activeChatMessagesProvider, (_, __) => _scrollToBottom());
    ref.listen(isLoadingProvider, (_, nextIsLoading) {
      // Scroll more reliably when loading starts/stops causing content shift
      if (nextIsLoading) _scrollToBottom(true); // Jump scroll when loading starts
       // Consider scrolling when loading FINISHES as well, in case content jumped
      // else { _scrollToBottom(); }
    });

    // Scroll when the session changes and messages load for the first time
    ref.listen(activeChatSessionProvider, (_, nextSession) {
         if (nextSession != null) {
            // Needs a slight delay for messages to potentially load/render?
            Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom(true));
         }
    });


    return Container(
      color: const Color(0xFF202124),
      child: Column(
        children: [
          // --- Top Bar (Desktop) ---
          if (!widget.isMobileLayout)
            _buildDesktopTopBar(context, currentSession?.displayTitle ?? "Chat"),

          // --- Web Search Toggle Switch ---
          // Place it discreetly, maybe above the input field
          Container(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobileLayout ? 16.0 : 48.0,
                  vertical: 4.0 // Small vertical padding
              ),
              color: const Color(0xFF202124), // Match background
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                        'Web Search: ',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])
                    ),
                    SizedBox(
                         height: 20, // Constrain height
                        child: Switch(
                            value: isWebSearchEnabled,
                           onChanged: isLoading ? null : (value) { // Disable when loading
                                ref.read(isWebSearchEnabledProvider.notifier).state = value;
                                debugPrint("Web Search: $value");
                                
                            },
                            activeColor: Colors.blue[300],
                            inactiveThumbColor: Colors.grey[600],
                            inactiveTrackColor: Colors.grey[800],
                             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Smaller tap target
                         ),
                     ),
                     const SizedBox(width: 8) // Add some spacing if needed
                  ],
              ),
          ),

          // --- Main Chat Area ---
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.isMobileLayout ? 16.0 : 48.0),
                // Use GestureDetector to dismiss keyboard when tapping chat area
               child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: _buildChatListOrPlaceholder(context, messages, currentSession),
                ),
            ),
          ),

          // --- Loading Indicator and Error Display ---
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent, color: Colors.blue),
            ),
          chatControllerState.maybeWhen(
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text("Error: $error", style: TextStyle(color: Colors.red[300], fontSize: 12)),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          // --- Input Field Area ---
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isMobileLayout ? 12.0 : 48.0,
              8.0, // Top padding reduced slightly
              widget.isMobileLayout ? 12.0 : 48.0,
              16.0,
            ),
            child: DynamicInputField(
              isLoading: isLoading,
              onSend: _sendTextMessage,
              onSendFile: _sendFileMessage, // Wire up file sending
              onSendAudio: _sendAudioMessage, // Wire up audio sending
            ),
          ),
        ],
      ),
    );
  }

  // --- Desktop Top Bar (Keep existing implementation) ---
  Widget _buildDesktopTopBar(BuildContext context, String title){
    // ... (your existing code for the top bar) ...
      return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12), // Adjusted padding
          decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
          child: Row(
             children: [
             Expanded(
                 child: Text(
                 title,
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[300]),
                 overflow: TextOverflow.ellipsis,
                 ),
             ),
             // Add top bar actions if needed (Save, Clear, Info etc.)
             IconButton(
                 icon: const Icon(Icons.settings_outlined),
                 tooltip: 'Settings',
                 onPressed: () {
                 Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const SettingsPage()),
                 );
                 },
             ),
             IconButton(onPressed: (){}, icon: Icon(Icons.save_alt_outlined, color: Colors.grey[400], size: 20)),
             IconButton(onPressed: (){}, icon: Icon(Icons.cleaning_services_outlined, color: Colors.grey[400], size: 20)),
             ],
          ),
     );
  }

  // --- Chat List or Placeholder (Keep existing implementation) ---
  Widget _buildChatListOrPlaceholder(BuildContext context, List<ChatMessage> messages, ChatSessionItem? currentSession) {
    if (currentSession == null && messages.isEmpty) {
      return _buildGettingStartedPlaceholder(context);
    } else if (messages.isEmpty && currentSession != null) { // Check currentSession exists
        // Show different message if session is selected but empty
        return Center(child: Text("Send a message or file to start...", style: TextStyle(color: Colors.grey[500])));
    } else if (messages.isEmpty) { // Fallback (shouldn't be easily reachable if first condition is met)
         return _buildGettingStartedPlaceholder(context);
    }
    else {
      // Display chat messages
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Adjusted padding
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          // Use message.id or a combination as Key for better state preservation
          return ChatMessageWidget(key: ValueKey(message.id), message: message);
        },
      );
    }
  }

  // --- Getting Started Placeholder (Keep existing implementation) ---
  Widget _buildGettingStartedPlaceholder(BuildContext context) {
    // ... (your existing code for the placeholder) ...
      return Center(
         child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
             Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[600]),
             const SizedBox(height: 20),
             Text("Select a chat or start a new one", style: TextStyle(fontSize: 18, color: Colors.grey[500])),
             const SizedBox(height: 8),
             Text("Your conversations will appear here.", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
             ],
         ),
     );
  }
}