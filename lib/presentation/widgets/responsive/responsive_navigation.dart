import 'package:flutter/material.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';

class ResponsiveNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const ResponsiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildBottomNavigation(),
      tablet: _buildNavigationRail(),
      desktop: _buildSideNavigation(context),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.selected,
      destinations: items
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ))
          .toList(),
    );
  }

  Widget _buildSideNavigation(BuildContext context) {
    return Container(
      width: ResponsiveUtils.responsiveValue(
        mobile: 200,
        tablet: 250,
        desktop: 300,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: ResponsiveUtils.responsivePadding(),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.responsiveValue(
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
                SizedBox(width: AppConstants.spacingM),
                Text(
                  'AI Studio',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      baseFontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(AppConstants.spacingM),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                
                return Container(
                  margin: EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: isSelected,
                    onTap: () => onTap(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String? route;

  const NavigationItem({
    required this.icon,
    required this.label,
    this.route,
  });
}