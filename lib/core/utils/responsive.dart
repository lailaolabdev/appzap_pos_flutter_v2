import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive breakpoints for mobile, tablet, and desktop layouts
class Responsive {
  Responsive._(); // Private constructor

  /// Mobile breakpoint (< 600px width)
  static const double mobile = 600;

  /// Tablet breakpoint (600px - 1024px width)
  static const double tablet = 1024;

  /// Desktop breakpoint (> 1024px width)
  static const double desktop = 1200;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get sidebar width based on screen size
  /// Returns 0 for mobile (uses drawer), 80 for tablet/desktop (persistent)
  static double getSidebarWidth(BuildContext context) {
    return isMobile(context) ? 0 : 80;
  }

  /// Get cart panel width based on screen size
  /// Returns screen width for mobile, proportional for tablet/desktop
  static double getCartPanelWidth(BuildContext context) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    // Use ~35% of screen width, clamped between 300-400
    return (screenWidth * 0.35).clamp(300, 400);
  }

  /// Check if sidebar should be in drawer mode (mobile)
  static bool shouldUseSidebarDrawer(BuildContext context) {
    return isMobile(context);
  }

  /// Check if sidebar should be persistent (tablet/desktop)
  static bool shouldShowPersistentSidebar(BuildContext context) {
    return !isMobile(context);
  }

  /// Get dialog width that fits any screen
  /// Returns proportional width capped at [maxWidth]
  static double getDialogWidth(BuildContext context, {double maxWidth = 600}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return min(screenWidth * 0.9, maxWidth);
  }

  /// Get dialog height that fits any screen
  /// Returns proportional height capped at [maxHeight]
  static double getDialogHeight(BuildContext context, {double maxHeight = 700}) {
    final screenHeight = MediaQuery.of(context).size.height;
    return min(screenHeight * 0.85, maxHeight);
  }

  /// Get responsive PIN/OTP field width based on screen width and field count
  static double getPinFieldWidth(BuildContext context, {int fieldCount = 4}) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Available width = screen width - padding (48px each side) - gaps between fields
    final availableWidth = screenWidth - 96 - ((fieldCount - 1) * 10);
    final fieldWidth = (availableWidth / fieldCount).floorToDouble();
    return fieldWidth.clamp(40, 60);
  }

  /// Get responsive PIN/OTP field height
  static double getPinFieldHeight(BuildContext context) {
    final fieldWidth = getPinFieldWidth(context);
    return fieldWidth.clamp(44, 60);
  }
}

