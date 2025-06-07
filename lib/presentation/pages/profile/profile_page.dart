import 'package:flutter/material.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/responsive_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile
          ? AppBar(
              title: const Text('Profile'),
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
          _buildProfileHeader(context),
          const SizedBox(height: AppConstants.spacingL),
          _buildStatsCard(context),
          const SizedBox(height: AppConstants.spacingL),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(),
      child: Column(
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: AppConstants.spacingXL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStatsCard(context),
              ),
              const SizedBox(width: AppConstants.spacingL),
              Expanded(
                child: _buildRecentActivity(context),
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
          _buildProfileHeader(context),
          const SizedBox(height: AppConstants.spacingXXL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildStatsCard(context),
              ),
              const SizedBox(width: AppConstants.spacingXL),
              Expanded(
                flex: 2,
                child: _buildRecentActivity(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.responsiveValue(
              mobile: 40,
              tablet: 50,
              desktop: 60,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.person,
              size: ResponsiveUtils.responsiveValue(
                mobile: 40,
                tablet: 50,
                desktop: 60,
              ),
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'AI Studio User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Welcome to your AI creative workspace',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileAction(
                context,
                icon: Icons.edit,
                label: 'Edit Profile',
                onTap: () => _editProfile(context),
              ),
              _buildProfileAction(
                context,
                icon: Icons.share,
                label: 'Share',
                onTap: () => _shareProfile(context),
              ),
              _buildProfileAction(
                context,
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => _openSettings(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildStatItem(
            context,
            icon: Icons.chat,
            label: 'Messages Sent',
            value: '127',
            color: Colors.blue,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildStatItem(
            context,
            icon: Icons.image,
            label: 'Images Generated',
            value: '23',
            color: Colors.purple,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildStatItem(
            context,
            icon: Icons.audiotrack,
            label: 'Audio Created',
            value: '8',
            color: Colors.green,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildStatItem(
            context,
            icon: Icons.access_time,
            label: 'Time Saved',
            value: '12h',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _viewAllActivity(context),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildActivityItem(
            context,
            icon: Icons.chat,
            title: 'Started a new conversation',
            subtitle: 'Asked about Flutter development',
            time: '2 hours ago',
            color: Colors.blue,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildActivityItem(
            context,
            icon: Icons.image,
            title: 'Generated an image',
            subtitle: 'A beautiful sunset over mountains',
            time: '5 hours ago',
            color: Colors.purple,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildActivityItem(
            context,
            icon: Icons.settings,
            title: 'Updated settings',
            subtitle: 'Changed theme to dark mode',
            time: '1 day ago',
            color: Colors.orange,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildActivityItem(
            context,
            icon: Icons.audiotrack,
            title: 'Created audio content',
            subtitle: 'Text-to-speech conversion',
            time: '2 days ago',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  void _editProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing coming soon!'),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile sharing coming soon!'),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    // Navigate to settings page
    // This would typically use the router
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening settings...'),
      ),
    );
  }

  void _viewAllActivity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full activity history coming soon!'),
      ),
    );
  }
}