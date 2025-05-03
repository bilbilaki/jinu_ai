// lib/presentation/widgets/center_content_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/models/chat_message.dart';
import 'package:jinu/data/models/chat_session_item.dart';
import '../providers/chat_providers.dart';
import '../providers/history_provider.dart'; // Need active session details
import 'chat_message_widget.dart';
import 'dynamic_input_field.dart';

class CenterContentPanel extends ConsumerStatefulWidget {
  final bool isMobileLayout;
  const CenterContentPanel({super.key, required this.isMobileLayout});

  @override
  ConsumerState<CenterContentPanel> createState() => _CenterContentPanelState();
}

class _CenterContentPanelState extends ConsumerState<CenterContentPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom([bool jump=false]) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Only auto-scroll if user is near the bottom
    final isNearBottom = maxScroll - currentScroll < 100;

    if (isNearBottom || jump) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_scrollController.hasClients) {
             _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
             );
         }
       });
    }
  }


  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(activeChatMessagesProvider);
    final currentSession = ref.watch(activeChatSessionProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final chatControllerState = ref.watch(chatControllerProvider); // Watch async state


    // Listen for message changes AND loading state changes to scroll
   ref.listen(activeChatMessagesProvider, (_, __) => _scrollToBottom());
   ref.listen(isLoadingProvider, (_, nextIsLoading) {
     if (nextIsLoading) _scrollToBottom(true); // Jump scroll when loading starts
   });


    return Container(
      color: const Color(0xFF202124), // Main background
      child: Column(
        children: [
          // --- Top Bar --- (Optional, depends on design)
          // Could show title, actions like save, clear, etc.
          // Kept minimal for now
          if(!widget.isMobileLayout) // Don't show top bar on mobile if AppBar is used
             _buildDesktopTopBar(context, currentSession?.displayTitle ?? "Chat"),


          // --- Main Chat Area ---
          Expanded(
            child: Padding(
              // Add more padding on desktop for readability
              padding: EdgeInsets.symmetric(horizontal: widget.isMobileLayout ? 16.0 : 48.0),
              child: _buildChatListOrPlaceholder(context, messages, currentSession),
            ),
          ),

         // --- Loading Indicator and Error Display ---
          if (isLoading)
             const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent,),
              ),
         // Show error from ChatController state
         chatControllerState.maybeWhen(
             error: (error, stackTrace) => Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                 child: Text("Error: $error", style: TextStyle(color: Colors.red[300], fontSize: 12)),
             ),
            orElse: () => const SizedBox.shrink(), // Show nothing otherwise
          ),

          // --- Input Field Area ---
           Padding(
             // More horizontal padding on desktop
             padding: EdgeInsets.fromLTRB(
                widget.isMobileLayout ? 12.0 : 48.0,
                8.0,
                widget.isMobileLayout ? 12.0 : 48.0,
                16.0 // Bottom padding
              ),
             child: DynamicInputField(
                isLoading: isLoading,
                onSend: (text) {
                   if (text.trim().isNotEmpty) {
                      ref.read(chatControllerProvider.notifier).sendMessage(text.trim());
                   }
                },
                // TODO: Implement onRecordStart, onFileUpload
             ),
           ),
        ],
      ),
    );
  }

  // Helper to build the top bar for Desktop
  Widget _buildDesktopTopBar(BuildContext context, String title){
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
                  // IconButton(onPressed: (){}, icon: Icon(Icons.save_alt_outlined, color: Colors.grey[400], size: 20)),
                  // IconButton(onPressed: (){}, icon: Icon(Icons.cleaning_services_outlined, color: Colors.grey[400], size: 20)),
                ],
             ),
        );
  }

  // Helper to build the chat list or the initial placeholder
  Widget _buildChatListOrPlaceholder(BuildContext context, List<ChatMessage> messages, ChatSessionItem? currentSession) {
       if (currentSession == null && messages.isEmpty) {
            return _buildGettingStartedPlaceholder(context); // No session selected yet
       } else if (messages.isEmpty) {
            return Center(child: Text("Send a message to start chatting...", style: TextStyle(color: Colors.grey[500]))); // Session exists but is empty
       } else {
            // Display chat messages
            return ListView.builder(
                 controller: _scrollController,
                 padding: const EdgeInsets.symmetric(vertical: 16.0),
                 itemCount: messages.length,
                 itemBuilder: (context, index) {
                   final message = messages[index];
                   return ChatMessageWidget(message: message);
                 },
            );
       }
  }


 // Placeholder when no chat is active
 Widget _buildGettingStartedPlaceholder(BuildContext context) {
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


