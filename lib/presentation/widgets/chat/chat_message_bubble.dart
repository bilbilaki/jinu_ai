import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/message.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isLoading = message.isLoading;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _buildAvatar(context, isUser),
          const SizedBox(width: AppConstants.spacingM),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.responsiveValue(
                mobile: MediaQuery.of(context).size.width * 0.8,
                tablet: MediaQuery.of(context).size.width * 0.7,
                desktop: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL).copyWith(
                      bottomRight: isUser 
                          ? const Radius.circular(AppConstants.radiusS)
                          : null,
                      bottomLeft: !isUser 
                          ? const Radius.circular(AppConstants.radiusS)
                          : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        _buildLoadingIndicator(context)
                      else
                        _buildMessageContent(context, isUser),
                      if (message.error != null)
                        _buildErrorMessage(context),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                _buildMessageInfo(context, isUser),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: AppConstants.spacingM),
          _buildAvatar(context, isUser),
        ],
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      radius: ResponsiveUtils.responsiveValue(
        mobile: 16,
        tablet: 18,
        desktop: 20,
      ),
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: ResponsiveUtils.responsiveValue(
          mobile: 16,
          tablet: 18,
          desktop: 20,
        ),
        color: isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context),
      child: SelectableText(
        message.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isUser
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: ResponsiveUtils.responsiveFontSize(
            baseFontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Text(
          'Thinking...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              message.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo(BuildContext context, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(message.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: ResponsiveUtils.responsiveFontSize(
              baseFontSize: 10,
            ),
          ),
        ),
        if (!isUser && !message.isLoading) ...[
          const SizedBox(width: AppConstants.spacingS),
          GestureDetector(
            onTap: () => _copyToClipboard(context),
            child: Icon(
              Icons.copy,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}