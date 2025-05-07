import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/presentation/screens/settings_page.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/left_navigation_panel.dart';
import '../widgets/center_content_panel.dart';
import '../widgets/right_settings_panel.dart';
import '../widgets/image_generating.dart';

class AiStudioHomePage extends ConsumerStatefulWidget {
  const AiStudioHomePage({super.key});

  @override
  _AiStudioHomePageConsumerState createState() =>
      _AiStudioHomePageConsumerState();
}

class _AiStudioHomePageConsumerState extends ConsumerState<AiStudioHomePage>
    with TickerProviderStateMixin {
  // Changed to TickerProviderStateMixin
  // Left Drawer Tab Controller
  late TabController _leftDrawerTabController;
  // Right Drawer Tab Controller
  late TabController _rightDrawerTabController;
  late TabController _ImageGenerationDrawerController;

  @override
  void initState() {
    super.initState();
    // Initialize tab controllers (3 tabs each)
    _leftDrawerTabController = TabController(length: 3, vsync: this);
    _rightDrawerTabController = TabController(length: 3, vsync: this);
    _ImageGenerationDrawerController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Dispose of tab controllers
    _leftDrawerTabController.dispose();
    _rightDrawerTabController.dispose();
    _ImageGenerationDrawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final double sidebarWidth = isSidebarCollapsed ? 60.0 : 260.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700; // Breakpoint for drawers
    final isMobile = screenWidth < 600; // Example breakpoint for mobile layout

    if (isSmallScreen) {
      // Mobile/Tablet Layout: Use Drawers with Tabs
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Studio'),
          backgroundColor: const Color(0xFF2d2f32),
          actions: [
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
          child: Column(
            children: [
              TabBar(
                controller: _leftDrawerTabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.query_builder_outlined),
                    text: 'History',
                  ),
                  Tab(icon: Icon(Icons.network_wifi_sharp), text: 'Web'),
                  Tab(
                    icon: Icon(Icons.assured_workload_rounded),
                    text: 'Coming Soon',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _leftDrawerTabController,
                  children: [
                    LeftNavigationPanel(
                      isMobileLayout: true,
                      isCollapsed: false,
                    ),
                    Center(child: Text('Categories Content')),
                    Center(child: Text('History Content')),
                  ],
                ),
              ),
            ],
          ),
        ),
        endDrawer: Drawer(
          backgroundColor: const Color(0xFF2d2f32),
          child: Column(
            children: [
              TabBar(
                controller: _rightDrawerTabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    text: 'Chat Param',
                  ),
                  Tab(
                    icon: Icon(Icons.photo_album_outlined),
                    text: 'Image generation',
                  ),
                  Tab(icon: Icon(Icons.translate), text: 'Translate'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _rightDrawerTabController,
                  children: [
                    RightSettingsPanel(),
                    Center(child: ImageGenerationDrawer()),
                    Center(child: Text('Translate Content')),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: CenterContentPanel(isMobileLayout: isSmallScreen),
      );
    } else {
      // Desktop Layout
      return Scaffold(
        body: Row(
          children: [
            // Animated Collapsible Sidebar with Tabs
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              width: sidebarWidth,
              color: const Color(0xFF2d2f32),
              child: Column(
                children: [
                  TabBar(
                    controller: _leftDrawerTabController,
                    isScrollable: false,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.query_builder_outlined),
                        text: 'History',
                      ),
                      Tab(icon: Icon(Icons.network_wifi_sharp), text: 'Web'),
                      Tab(
                        icon: Icon(Icons.assured_workload_rounded),
                        text: 'Coming Soon',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _leftDrawerTabController,
                      children: [
                        LeftNavigationPanel(
                          isMobileLayout: false,
                          isCollapsed: isSidebarCollapsed,
                        ),
                        Center(child: Text('Categories Content')),
                        Center(child: Text('History Content')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Center Content Panel
            Expanded(flex: 3, child: CenterContentPanel(isMobileLayout: false)),

            // Right Settings Panel with Tabs
            Container(
              width: 340,
              color: const Color(0xFF2d2f32),
              child: Column(
                children: [
                  TabBar(
                    controller: _rightDrawerTabController,
                    isScrollable: false,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.dashboard_customize_outlined),
                        text: 'Chat Param',
                      ),
                      Tab(
                        icon: Icon(Icons.photo_album_outlined),
                        text: 'Image generation',
                      ),
                      Tab(icon: Icon(Icons.translate), text: 'Translate'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _rightDrawerTabController,
                      children: [
                        RightSettingsPanel(),
                        Center(child: ImageGenerationDrawer()),
                        Center(child: Text('Translate Content')),
                      ],
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
}
