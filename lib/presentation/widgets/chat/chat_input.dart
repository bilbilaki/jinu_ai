import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../blocs/chat/chat_bloc.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isLoading = state.isLoading || state.isStreaming;
        
        return Container(
          padding: ResponsiveUtils.responsivePadding(),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: !isLoading,
                          maxLines: ResponsiveUtils.responsiveValue(
                            mobile: 4.0,
                            tablet: 6.0,
                            desktop: 8.0,
                          ).round(),
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: isLoading 
                                ? 'AI is thinking...' 
                                : 'Type your message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingL,
                              vertical: ResponsiveUtils.responsiveValue(
                                mobile: AppConstants.spacingM,
                                tablet: AppConstants.spacingL,
                                desktop: AppConstants.spacingL,
                              ),
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: ResponsiveUtils.responsiveFontSize(
                              baseFontSize: 14,
                            ),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _isComposing = text.trim().isNotEmpty;
                            });
                          },
                          onSubmitted: _isComposing && !isLoading 
                              ? (_) => _sendMessage() 
                              : null,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      if (ResponsiveUtils.isDesktop) ...[
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: isLoading ? null : _attachFile,
                          tooltip: 'Attach file',
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic),
                          onPressed: isLoading ? null : _recordVoice,
                          tooltip: 'Voice input',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              _buildSendButton(isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: _isComposing && !isLoading
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Icon(
                Icons.send,
                color: _isComposing && !isLoading
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        onPressed: _isComposing && !isLoading ? _sendMessage : null,
        tooltip: 'Send message',
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendChatMessage(content: text));
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
      _focusNode.requestFocus();
    }
  }

  void _attachFile() {
    // TODO: Implement file attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment coming soon!'),
      ),
    );
  }

  void _recordVoice() {
    // TODO: Implement voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input coming soon!'),
      ),
    );
  }
}