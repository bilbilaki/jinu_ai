import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import 'responsive_card.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(
                mobile: AppConstants.spacingM,
                tablet: AppConstants.spacingL,
                desktop: AppConstants.spacingL,
              ),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveUtils.responsiveValue(
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingM),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 16,
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingS),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: ResponsiveUtils.responsiveFontSize(
                baseFontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}