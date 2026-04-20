import 'package:flutter/material.dart';

/// Main app shell — always uses drawer-based sidebar (no persistent sidebar).
/// Each screen's Scaffold provides its own drawer with AppSidebar.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
