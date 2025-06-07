import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../widgets/chat/chat_message_list.dart';
import '../../widgets/chat/chat_input.dart';
import '../../widgets/common/responsive_card.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<ChatBloc>()..add(const LoadChatHistory()),
      child: const _ChatPageContent(),
    );
  }
}

class _ChatPageContent extends StatelessWidget {
  const _ChatPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile
          ? AppBar(
              title: const Text('AI Chat'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showClearChatDialog(context),
                ),
              ],
            )
          : null,
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: ChatMessageList()),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: const ChatInput(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.responsivePadding(),
      child: ResponsiveCard(
        child: Column(
          children: [
            _buildChatHeader(context),
            const Divider(),
            const Expanded(child: ChatMessageList()),
            const Divider(),
            const ChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.responsivePadding(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ResponsiveCard(
              child: Column(
                children: [
                  _buildChatHeader(context),
                  const Divider(),
                  const Expanded(child: ChatMessageList()),
                  const Divider(),
                  const ChatInput(),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingL),
          Expanded(
            flex: 1,
            child: _buildChatSidebar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ready to help you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearChatDialog(context),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildChatSidebar(BuildContext context) {
    return Column(
      children: [
        ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildSettingItem(
                context,
                icon: Icons.psychology,
                title: 'Model',
                subtitle: 'GPT-3.5 Turbo',
              ),
              _buildSettingItem(
                context,
                icon: Icons.thermostat,
                title: 'Temperature',
                subtitle: '0.7',
              ),
              _buildSettingItem(
                context,
                icon: Icons.token,
                title: 'Max Tokens',
                subtitle: '4096',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildQuickAction(
                context,
                icon: Icons.lightbulb_outline,
                title: 'Get Ideas',
                onTap: () => _sendQuickMessage(context, 'Give me some creative ideas'),
              ),
              _buildQuickAction(
                context,
                icon: Icons.help_outline,
                title: 'Ask Question',
                onTap: () => _sendQuickMessage(context, 'I have a question about'),
              ),
              _buildQuickAction(
                context,
                icon: Icons.code,
                title: 'Code Help',
                onTap: () => _sendQuickMessage(context, 'Help me with coding'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ChatBloc>().add(const ClearChat());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _sendQuickMessage(BuildContext context, String message) {
    context.read<ChatBloc>().add(SendChatMessage(content: message));
  }
}