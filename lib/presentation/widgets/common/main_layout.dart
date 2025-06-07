import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/app_router.dart';
import '../../blocs/navigation/navigation_cubit.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _MobileLayout(child: child),
      tablet: _TabletLayout(child: child),
      desktop: _DesktopLayout(child: child),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;

  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: child,
          bottomNavigationBar: _buildBottomNavigation(context, state),
          drawer: _buildDrawer(context),
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context, NavigationState state) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(context),
      onTap: (index) => _onNavigationTap(context, index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.image),
          label: 'Media',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final Widget child;

  const _TabletLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _getCurrentIndex(context),
                onDestinationSelected: (index) => _onNavigationTap(context, index),
                labelType: NavigationRailLabelType.selected,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat),
                    label: Text('Chat'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.image),
                    label: Text('Media'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;

  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildSideNavigation(context),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideNavigation(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Text(
                'AI Studio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'Home',
                route: AppRouter.home,
              ),
              _buildNavItem(
                context,
                icon: Icons.chat,
                label: 'Chat',
                route: AppRouter.chat,
              ),
              _buildNavItem(
                context,
                icon: Icons.image,
                label: 'Media',
                route: AppRouter.media,
              ),
              _buildNavItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                route: AppRouter.profile,
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildNavItem(
                context,
                icon: Icons.settings,
                label: 'Settings',
                route: AppRouter.settings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = GoRouterState.of(context).uri.path == route;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: isSelected,
        onTap: () => context.go(route),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }
}

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 48,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'AI Studio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRouter.home);
          },
        ),
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Chat'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRouter.chat);
          },
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text('Media'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRouter.media);
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRouter.profile);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRouter.settings);
          },
        ),
      ],
    ),
  );
}

int _getCurrentIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.path;
  switch (location) {
    case AppRouter.home:
      return 0;
    case AppRouter.chat:
      return 1;
    case AppRouter.media:
      return 2;
    case AppRouter.settings:
      return 3;
    default:
      return 0;
  }
}

void _onNavigationTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRouter.home);
      break;
    case 1:
      context.go(AppRouter.chat);
      break;
    case 2:
      context.go(AppRouter.media);
      break;
    case 3:
      context.go(AppRouter.settings);
      break;
  }
}