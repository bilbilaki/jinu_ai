import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:ai_studio_flutter/main.dart';
import 'package:ai_studio_flutter/core/di/injection_container.dart';

void main() {
  setUpAll(() async {
    // Initialize dependencies for testing
    await initializeDependencies();
  });

  tearDownAll(() {
    // Clean up GetIt instance
    GetIt.instance.reset();
  });

  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App should have proper theme configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    
    // Verify theme configuration
    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
    expect(app.themeMode, isNotNull);
  });

  testWidgets('App should have router configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    
    // Verify router configuration
    expect(app.routerConfig, isNotNull);
  });
}