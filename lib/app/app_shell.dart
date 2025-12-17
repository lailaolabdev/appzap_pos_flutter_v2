import 'package:flutter/material.dart';

import '../core/utils/responsive.dart';
import '../shared/widgets/app_sidebar.dart';

/// Main app shell layout with responsive sidebar navigation
/// 
/// Provides:
/// - Persistent sidebar for tablet/desktop (≥ 600px)
/// - Drawer sidebar for mobile (< 600px) with hamburger menu
/// - Consistent navigation across all devices
/// 
/// Layout:
/// Mobile:            Desktop/Tablet:
/// ┌─────────────┐   ┌───┬────────┐
/// │ ☰ AppBar   │   │   │ AppBar │
/// ├─────────────┤   │ S ├────────┤
/// │             │   │ i │        │
/// │   Body      │   │ d │  Body  │
/// │   Content   │   │ e │ Content│
/// │             │   │ b │        │
/// │             │   │ a │        │
/// └─────────────┘   │ r │        │
///                   └───┴────────┘
///                   80px   Flex
///
/// Mobile drawer opens from left on hamburger tap
class AppShell extends StatelessWidget {
  final Widget child;
  final bool enableDrawer;

  const AppShell({
    super.key,
    required this.child,
    this.enableDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // On mobile: just wrap child (Scaffold) - drawer will be added by child
    // On tablet: add sidebar to the left of child
    if (isMobile) {
      // Mobile: Return child directly but with drawer support
      // The child Scaffold will handle its own drawer
      return child;
    } else {
      // Tablet/Desktop: Add persistent sidebar
      return Row(
        children: [
          const AppSidebar(isInDrawer: false),
          Expanded(child: child),
        ],
      );
    }
  }
}

