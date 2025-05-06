// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/presentation/screens/settings_page.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/left_navigation_panel.dart';
import '../widgets/center_content_panel.dart';
import '../widgets/right_settings_panel.dart';

class AiStudioHomePage extends ConsumerWidget {
  const AiStudioHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final double sidebarWidth = isSidebarCollapsed ? 60.0 : 260.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800; // Breakpoint for drawers

  
    final isMobile = screenWidth < 700; // Example breakpoint for mobile layout

    if (isSmallScreen) {
      // Mobile/Tablet Layout: Use Drawers
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Studio'), // Or dynamic title?
          backgroundColor: const Color(0xFF2d2f32),
          // Leading automatically shows hamburger for drawer
          actions: [
            // Navigate to full Settings Page on mobile
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF2d2f32),
          child: LeftNavigationPanel(
            isMobileLayout: true,
            isCollapsed: false,
          ),
        ),
        endDrawer: Drawer(
          // Right Drawer for Settings
          backgroundColor: const Color(0xFF2d2f32),
          // Right Drawer for Settings
          child: RightSettingsPanel(),
        ),
        body: CenterContentPanel(isMobileLayout: isSmallScreen,
        ), // Pass mobile flag to center panel

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Action for FAB, e.g., new chat
          },
          backgroundColor: const Color(0xFF2d2f32),
          child: const Icon(Icons.add),
        ),
      );
    } else {
      // Desktop Layout
      return Scaffold(
        body: Row(
          children: [
            // Animated Collapsible Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic, // Smoother curve
              width: sidebarWidth,
              color: const Color(0xFF2d2f32),
              child: LeftNavigationPanel(
                isMobileLayout: false,
                isCollapsed: isSidebarCollapsed,
              ),
            ),

            // Center Content Panel
            Expanded(
              flex: 3, // Give more space
              child: CenterContentPanel(isMobileLayout: false),
            ),

            // Right Settings Panel
            Container(
              width: 340, // Slightly wider?
              color: const Color(0xFF2d2f32),
              child: const RightSettingsPanel(),
            ),
          ],
        ),
      );
    }
  }
}
