// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/ai_studio_home_page.dart';
import 'presentation/providers/settings_provider.dart'; // To get theme mode

class AiStudioCloneApp extends ConsumerWidget { // Use ConsumerWidget
  const AiStudioCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    // Watch the theme mode provider
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AI Studio Clone',
      themeMode: themeMode, // Set theme mode dynamically
      // Define Light Theme
      theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            // Define light theme colors, fonts, etc.
            colorScheme: ColorScheme.fromSeed(
                 seedColor: Colors.blue,
                 brightness: Brightness.light,
            ),
            cardColor: Colors.white,
            scaffoldBackgroundColor: Colors.grey[100], // Light background
            // Customize other components for light theme
            inputDecorationTheme: InputDecorationTheme(
                 filled: true,
                 fillColor: Colors.grey[200],
                 border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                  ),
                hintStyle: TextStyle(color: Colors.grey[600]),
             ),
               appBarTheme: AppBarTheme(
                  backgroundColor: Colors.grey[50], // Lighter App Bar
                 foregroundColor: Colors.black87,
                elevation: 0.5,
             ),
             drawerTheme: DrawerThemeData(
                backgroundColor: Colors.grey[50]
            ),
         // Add other light theme customizations
      ),
      // Define Dark Theme (Based on your original setup)
      darkTheme: ThemeData(
           brightness: Brightness.dark,
           useMaterial3: true,
            // Dark theme colors
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                 brightness: Brightness.dark,
                background: const Color(0xFF202124), // Main background
                surface: const Color(0xFF2d2f32), // Sidebar/Drawer background
                onSurface: Colors.grey[300]!, // Text on surface
                primary: Colors.blue[300]!,
                secondary: Colors.teal[300]!,
                 // error: Colors.red[400]!,
           ),
           scaffoldBackgroundColor: const Color(0xFF202124),
            cardColor: const Color(0xFF2d2f32), // Card color for message bubbles etc.
            primaryColor: Colors.blue[300],
            hintColor: Colors.grey[500], // Hint text color
            chipTheme: ChipThemeData(
                 backgroundColor: Colors.grey[700],
                 labelStyle: TextStyle(color: Colors.grey[200]),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                 side: BorderSide(color: Colors.grey[600]!)
            ),
             textButtonTheme: TextButtonThemeData(
                 style: TextButton.styleFrom(foregroundColor: Colors.blue[300])),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
               fillColor: Colors.grey[800], // Original input fill
               border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                   borderSide: BorderSide.none,
               ),
               hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            sliderTheme: SliderThemeData(
                activeTrackColor: Colors.blue[400],
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.blue[300],
                overlayColor: Colors.blue.withOpacity(0.2),
            ),
            switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                    states.contains(MaterialState.selected) ? Colors.blue[300] : Colors.grey[600]),
                trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                    states.contains(MaterialState.selected) ? Colors.blue[300]?.withOpacity(0.5) : Colors.grey[800]),
             ),
             appBarTheme: AppBarTheme(
                 backgroundColor: const Color(0xFF2d2f32),
                 foregroundColor: Colors.grey[300],
                 elevation: 1, // Slight elevation for definition
             ),
              drawerTheme: const DrawerThemeData(
                  backgroundColor: Color(0xFF2d2f32)
             ),
             // Add more specific dark theme customizations if needed
           listTileTheme: ListTileThemeData(
                selectedColor: Colors.white, // Text color for selected item
                selectedTileColor: Colors.grey[700], // Background for selected item
              iconColor: Colors.grey[400],
           ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
                color: Colors.blue[300],
               linearMinHeight: 2.5,
             ),
      ),
      home: const AiStudioHomePage(), // Your main layout screen
      debugShowCheckedModeBanner: false,
    );
  }
}