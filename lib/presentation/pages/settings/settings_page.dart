import 'package:flutter/material.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/responsive_card.dart';
import '../../widgets/settings/theme_settings.dart';
import '../../widgets/settings/ai_settings.dart';
import '../../widgets/settings/general_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile
          ? AppBar(
              title: const Text('Settings'),
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
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildSettingsHeader(context),
          const SizedBox(height: AppConstants.spacingL),
          const ThemeSettings(),
          const SizedBox(height: AppConstants.spacingL),
          const AISettings(),
          const SizedBox(height: AppConstants.spacingL),
          const GeneralSettings(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildSettingsHeader(context),
          const SizedBox(height: AppConstants.spacingXL),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    ThemeSettings(),
                    SizedBox(height: AppConstants.spacingL),
                    GeneralSettings(),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.spacingL),
              Expanded(
                child: AISettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildSettingsHeader(context),
          const SizedBox(height: AppConstants.spacingXXL),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    ThemeSettings(),
                    SizedBox(height: AppConstants.spacingL),
                    GeneralSettings(),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.spacingXL),
              Expanded(
                flex: 1,
                child: AISettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(BuildContext context) {
    return ResponsiveCard(
      child: Row(
        children: [
          Icon(
            Icons.settings,
            size: ResponsiveUtils.responsiveValue(
              mobile: 32,
              tablet: 40,
              desktop: 48,
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Customize your AI Studio experience',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}