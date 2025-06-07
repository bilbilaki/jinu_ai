import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/media_content.dart';
import '../common/responsive_card.dart';

class MediaItemCard extends StatelessWidget {
  final MediaContent media;

  const MediaItemCard({
    super.key,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: () => _showMediaDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildMediaPreview(context),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildMediaInfo(context),
          const SizedBox(height: AppConstants.spacingS),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: _buildPreviewContent(context),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    switch (media.type) {
      case MediaContentType.image:
        if (media.url != null) {
          return Image.network(
            media.url!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingIndicator(context);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorIndicator(context);
            },
          );
        } else {
          return _buildPlaceholder(context, Icons.image, 'Image');
        }
      case MediaContentType.audio:
        return _buildPlaceholder(context, Icons.audiotrack, 'Audio');
      case MediaContentType.video:
        return _buildPlaceholder(context, Icons.videocam, 'Video');
    }
  }

  Widget _buildPlaceholder(BuildContext context, IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.responsiveValue(
              mobile: 32,
              tablet: 40,
              desktop: 48,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Failed to load',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          media.prompt,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Row(
          children: [
            Icon(
              _getStatusIcon(),
              size: 16,
              color: _getStatusColor(context),
            ),
            const SizedBox(width: AppConstants.spacingXS),
            Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(context),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(media.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyPrompt(context),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: media.url != null ? () => _downloadMedia(context) : null,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Save'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (media.status) {
      case MediaStatus.generating:
        return Icons.hourglass_empty;
      case MediaStatus.completed:
        return Icons.check_circle;
      case MediaStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (media.status) {
      case MediaStatus.generating:
        return Theme.of(context).colorScheme.primary;
      case MediaStatus.completed:
        return Theme.of(context).colorScheme.tertiary;
      case MediaStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getStatusText() {
    switch (media.status) {
      case MediaStatus.generating:
        return 'Generating...';
      case MediaStatus.completed:
        return 'Completed';
      case MediaStatus.failed:
        return 'Failed';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showMediaDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${media.type.toString().split('.').last.toUpperCase()} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prompt: ${media.prompt}'),
            const SizedBox(height: AppConstants.spacingM),
            Text('Status: ${_getStatusText()}'),
            const SizedBox(height: AppConstants.spacingM),
            Text('Created: ${media.createdAt}'),
            if (media.parameters != null) ...[
              const SizedBox(height: AppConstants.spacingM),
              Text('Parameters: ${media.parameters}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyPrompt(BuildContext context) {
    Clipboard.setData(ClipboardData(text: media.prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prompt copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadMedia(BuildContext context) {
    // TODO: Implement media download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}