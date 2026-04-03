import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import 'printer_settings_page.dart';
import 'language_settings_page.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localizationProvider).languageCode;
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        body: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.menu, size: 24),
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    if (!isMobile) const SizedBox(width: 16),
                    Text(
                      Translations.get('settings', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),

              // Settings list
              Expanded(
                child: ListView(
                  children: [
                    // Printers
                    _buildSettingsItem(
                      icon: Icons.print,
                      label: Translations.get('printers', lang),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrinterSettingsPage(),
                            ),
                          ),
                    ),

                    // Language
                    _buildSettingsItem(
                      icon: Icons.language,
                      label: Translations.get('language', lang),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LanguageSettingsPage(),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade600),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
