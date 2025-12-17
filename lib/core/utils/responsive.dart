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
  /// Returns screen width for mobile, 350 for tablet/desktop
  static double getCartPanelWidth(BuildContext context) {
    return isMobile(context) 
        ? MediaQuery.of(context).size.width 
        : 350;
  }

  /// Check if sidebar should be in drawer mode (mobile)
  static bool shouldUseSidebarDrawer(BuildContext context) {
    return isMobile(context);
  }

  /// Check if sidebar should be persistent (tablet/desktop)
  static bool shouldShowPersistentSidebar(BuildContext context) {
    return !isMobile(context);
  }
}

