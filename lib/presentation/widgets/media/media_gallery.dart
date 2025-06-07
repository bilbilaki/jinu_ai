import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/media_content.dart';
import '../../blocs/media/media_bloc.dart';
import '../common/responsive_card.dart';
import 'media_item_card.dart';

class MediaGallery extends StatelessWidget {
  const MediaGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generated Media',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // TODO: Implement refresh functionality
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Expanded(
            child: BlocBuilder<MediaBloc, MediaState>(
              builder: (context, state) {
                if (state.isGenerating && state.mediaHistory.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.mediaHistory.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _buildMediaGrid(context, state.mediaHistory);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: ResponsiveUtils.responsiveValue(
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'No media generated yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Generate your first image or audio using the form on the left.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<MediaContent> mediaList) {
    final crossAxisCount = ResponsiveUtils.responsiveValue(
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: ResponsiveUtils.responsiveValue(
          mobile: 1.2,
          tablet: 1.0,
          desktop: 0.8,
        ),
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[mediaList.length - 1 - index]; // Reverse order
        return MediaItemCard(media: media);
      },
    );
  }
}