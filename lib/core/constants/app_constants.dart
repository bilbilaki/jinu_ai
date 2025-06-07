class AppConstants {
  // App Info
  static const String appName = 'AI Studio';
  static const String appVersion = '1.0.0';
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // AI Model Constants
  static const int maxTokens = 4096;
  static const double defaultTemperature = 0.7;
  static const int maxHistoryLength = 50;
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(seconds: 60);
}