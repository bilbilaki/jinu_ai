import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/app_router.dart';
import '../../widgets/common/responsive_card.dart';
import '../../widgets/common/feature_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile
          ? AppBar(
              title: const Text('AI Studio'),
              centerTitle: true,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: AppConstants.spacingXL),
          _buildQuickActions(context),
          const SizedBox(height: AppConstants.spacingXL),
          _buildFeatures(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: AppConstants.spacingXL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildQuickActions(context),
              ),
              const SizedBox(width: AppConstants.spacingL),
              Expanded(
                flex: 3,
                child: _buildFeatures(context),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: AppConstants.spacingXXL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildQuickActions(context),
              ),
              const SizedBox(width: AppConstants.spacingXL),
              Expanded(
                flex: 2,
                child: _buildFeatures(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: ResponsiveUtils.responsiveValue(
                  mobile: 32,
                  tablet: 40,
                  desktop: 48,
                ),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to AI Studio',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          baseFontSize: 24,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Your creative AI companion for chat, image generation, and audio creation.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          baseFontSize: 16,
                        ),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildActionButton(
          context,
          icon: Icons.chat,
          title: 'Start Chat',
          subtitle: 'Begin a conversation with AI',
          onTap: () => context.go(AppRouter.chat),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildActionButton(
          context,
          icon: Icons.image,
          title: 'Generate Image',
          subtitle: 'Create images from text',
          onTap: () => context.go(AppRouter.media),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildActionButton(
          context,
          icon: Icons.audiotrack,
          title: 'Generate Audio',
          subtitle: 'Create audio content',
          onTap: () => context.go(AppRouter.media),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ResponsiveCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveUtils.responsiveColumns(),
          crossAxisSpacing: AppConstants.spacingM,
          mainAxisSpacing: AppConstants.spacingM,
          children: [
            FeatureCard(
              icon: Icons.chat_bubble_outline,
              title: 'AI Chat',
              description: 'Intelligent conversations with advanced AI models',
              color: Colors.blue,
            ),
            FeatureCard(
              icon: Icons.image_outlined,
              title: 'Image Generation',
              description: 'Create stunning images from text descriptions',
              color: Colors.purple,
            ),
            FeatureCard(
              icon: Icons.audiotrack_outlined,
              title: 'Audio Creation',
              description: 'Generate speech and audio content',
              color: Colors.green,
            ),
            FeatureCard(
              icon: Icons.settings_outlined,
              title: 'Customizable',
              description: 'Personalize your AI experience',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}