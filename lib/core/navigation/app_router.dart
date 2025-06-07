import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/chat/chat_page.dart';
import '../../presentation/pages/media/media_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/widgets/common/main_layout.dart';

class AppRouter {
  static const String home = '/';
  static const String chat = '/chat';
  static const String media = '/media';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: chat,
            name: 'chat',
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: media,
            name: 'media',
            builder: (context, state) => const MediaPage(),
          ),
          GoRoute(
            path: settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );

  static void navigateTo(BuildContext context, String route) {
    context.go(route);
  }

  static void navigateToNamed(BuildContext context, String name, {Map<String, String>? params}) {
    context.goNamed(name, pathParameters: params ?? {});
  }
}