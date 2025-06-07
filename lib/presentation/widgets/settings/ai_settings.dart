import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../common/responsive_card.dart';

class AISettings extends StatelessWidget {
  const AISettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Configuration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildModelSelector(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildTemperatureSlider(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildMaxTokensSlider(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildStreamingToggle(context, state),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, ThemeState state) {
    final models = [
      'gpt-3.5-turbo',
      'gpt-4',
      'gpt-4-turbo',
      'claude-3-sonnet',
      'claude-3-opus',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Model',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        DropdownButtonFormField<String>(
          value: state.settings.aiModel,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.all(AppConstants.spacingM),
          ),
          items: models.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: (newModel) {
            if (newModel != null) {
              final updatedSettings = state.settings.copyWith(aiModel: newModel);
              context.read<ThemeCubit>().updateAppSettings(updatedSettings);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTemperatureSlider(BuildContext context, ThemeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Temperature',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              state.settings.temperature.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'Controls randomness in AI responses',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Slider(
          value: state.settings.temperature,
          min: 0.0,
          max: 2.0,
          divisions: 20,
          label: state.settings.temperature.toStringAsFixed(1),
          onChanged: (value) {
            final updatedSettings = state.settings.copyWith(temperature: value);
            context.read<ThemeCubit>().updateAppSettings(updatedSettings);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focused',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Creative',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaxTokensSlider(BuildContext context, ThemeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Max Tokens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              state.settings.maxTokens.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'Maximum length of AI responses',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Slider(
          value: state.settings.maxTokens.toDouble(),
          min: 256,
          max: 8192,
          divisions: 31,
          label: state.settings.maxTokens.toString(),
          onChanged: (value) {
            final updatedSettings = state.settings.copyWith(maxTokens: value.round());
            context.read<ThemeCubit>().updateAppSettings(updatedSettings);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Short',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Long',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreamingToggle(BuildContext context, ThemeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streaming Responses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                'Show AI responses as they are generated',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: state.settings.streamingEnabled,
          onChanged: (value) {
            final updatedSettings = state.settings.copyWith(streamingEnabled: value);
            context.read<ThemeCubit>().updateAppSettings(updatedSettings);
          },
        ),
      ],
    );
  }
}