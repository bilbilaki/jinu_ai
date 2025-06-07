import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../common/responsive_card.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildLanguageSelector(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildNotificationsToggle(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildActionButtons(context),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, ThemeState state) {
    final languages = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        DropdownButtonFormField<String>(
          value: state.settings.language,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.all(AppConstants.spacingM),
          ),
          items: languages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (newLanguage) {
            if (newLanguage != null) {
              final updatedSettings = state.settings.copyWith(language: newLanguage);
              context.read<ThemeCubit>().updateAppSettings(updatedSettings);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsToggle(BuildContext context, ThemeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                'Receive notifications about app updates and features',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: state.settings.notificationsEnabled,
          onChanged: (value) {
            final updatedSettings = state.settings.copyWith(notificationsEnabled: value);
            context.read<ThemeCubit>().updateAppSettings(updatedSettings);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportSettings(context),
                icon: const Icon(Icons.download),
                label: const Text('Export Settings'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _importSettings(context),
                icon: const Icon(Icons.upload),
                label: const Text('Import Settings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _resetSettings(context),
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  void _exportSettings(BuildContext context) {
    // TODO: Implement settings export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings export coming soon!'),
      ),
    );
  }

  void _importSettings(BuildContext context) {
    // TODO: Implement settings import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings import coming soon!'),
      ),
    );
  }

  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Implement settings reset
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset functionality coming soon!'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}