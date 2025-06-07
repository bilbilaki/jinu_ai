import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveHelper extends StatelessWidget {
  final Widget child;

  const ResponsiveHelper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ResponsiveUtils.updateScreenSize(constraints.maxWidth);
        return child;
      },
    );
  }
}

class ResponsiveUtils {
  static double _screenWidth = 0;

  static void updateScreenSize(double width) {
    _screenWidth = width;
  }

  static double get screenWidth => _screenWidth;

  static DeviceType get deviceType {
    if (_screenWidth < AppConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (_screenWidth < AppConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool get isMobile => deviceType == DeviceType.mobile;
  static bool get isTablet => deviceType == DeviceType.tablet;
  static bool get isDesktop => deviceType == DeviceType.desktop;

  static double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  static int responsiveColumns() {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }

  static EdgeInsets responsivePadding() {
    return EdgeInsets.all(
      responsiveValue(
        mobile: AppConstants.spacingM,
        tablet: AppConstants.spacingL,
        desktop: AppConstants.spacingXL,
      ),
    );
  }

  static double responsiveFontSize({
    required double baseFontSize,
    double scaleFactor = 1.0,
  }) {
    final scale = responsiveValue(
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    return baseFontSize * scale * scaleFactor;
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ResponsiveUtils.updateScreenSize(constraints.maxWidth);
        
        switch (ResponsiveUtils.deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}