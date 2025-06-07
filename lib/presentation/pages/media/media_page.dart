import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/media_content.dart';
import '../../blocs/media/media_bloc.dart';
import '../../widgets/common/responsive_card.dart';
import '../../widgets/media/media_generation_form.dart';
import '../../widgets/media/media_gallery.dart';

class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<MediaBloc>(),
      child: const _MediaPageContent(),
    );
  }
}

class _MediaPageContent extends StatelessWidget {
  const _MediaPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile
          ? AppBar(
              title: const Text('Media Generation'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showClearMediaDialog(context),
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.add), text: 'Generate'),
              Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),
          const Expanded(
            child: TabBarView(
              children: [
                MediaGenerationForm(),
                MediaGallery(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildMediaHeader(context),
          const SizedBox(height: AppConstants.spacingL),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: MediaGenerationForm(),
                ),
                SizedBox(width: AppConstants.spacingL),
                Expanded(
                  flex: 3,
                  child: MediaGallery(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildMediaHeader(context),
          const SizedBox(height: AppConstants.spacingXL),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: MediaGenerationForm(),
                ),
                SizedBox(width: AppConstants.spacingXL),
                Expanded(
                  flex: 2,
                  child: MediaGallery(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaHeader(BuildContext context) {
    return ResponsiveCard(
      child: Row(
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
          const SizedBox(width: AppConstants.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Generation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Create images and audio content using AI',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearMediaDialog(context),
            tooltip: 'Clear All Media',
          ),
        ],
      ),
    );
  }

  void _showClearMediaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Media'),
        content: const Text('Are you sure you want to clear all generated media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MediaBloc>().add(const ClearMediaHistory());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}