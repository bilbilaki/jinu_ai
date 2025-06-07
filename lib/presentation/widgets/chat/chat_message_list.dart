import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../blocs/chat/chat_bloc.dart';
import 'chat_message_bubble.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.animationMedium,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.messages.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: ResponsiveUtils.responsivePadding(),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: ChatMessageBubble(message: message),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: ResponsiveUtils.responsiveValue(
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Type a message below to begin chatting with the AI assistant.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          Wrap(
            spacing: AppConstants.spacingM,
            runSpacing: AppConstants.spacingM,
            children: [
              _buildSuggestionChip(
                context,
                'Tell me a joke',
                Icons.sentiment_very_satisfied,
              ),
              _buildSuggestionChip(
                context,
                'Explain quantum physics',
                Icons.science,
              ),
              _buildSuggestionChip(
                context,
                'Write a poem',
                Icons.edit,
              ),
              _buildSuggestionChip(
                context,
                'Help with coding',
                Icons.code,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      onPressed: () {
        context.read<ChatBloc>().add(SendChatMessage(content: text));
      },
    );
  }
}