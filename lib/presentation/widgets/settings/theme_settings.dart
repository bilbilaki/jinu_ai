import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../common/responsive_card.dart';

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildThemeModeSelector(context, state),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildFontSizeSlider(context, state),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, ThemeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {state.themeMode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            context.read<ThemeCubit>().changeTheme(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, ThemeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${state.settings.fontSize.round()}px',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Slider(
          value: state.settings.fontSize,
          min: 12.0,
          max: 20.0,
          divisions: 8,
          label: '${state.settings.fontSize.round()}px',
          onChanged: (value) {
            final updatedSettings = state.settings.copyWith(fontSize: value);
            context.read<ThemeCubit>().updateAppSettings(updatedSettings);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Small',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Large',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}