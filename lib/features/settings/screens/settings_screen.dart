import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import 'printer_settings_page.dart';
import 'language_settings_page.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final localization = ref.watch(localizationProvider);
    final lang = localization.languageCode;
    final isMobile = Responsive.isMobile(context);

    return AppShell(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        drawer:
            isMobile ? const Drawer(child: AppSidebar(isInDrawer: true)) : null,
        appBar: AppBar(
          leading:
              isMobile
                  ? Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                  )
                  : null,
          title: Text(Translations.get('settings', lang)),
        ),
        body: Column(
          children: [
            if (settingsState.error != null)
              ErrorBanner(message: settingsState.error!),
            Expanded(child: _buildSettingsList(settingsState, lang)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(SettingsState settingsState, String lang) {
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Printer Settings Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.print, size: 32),
              title: Text(
                Translations.get('printer', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrinterSettingsPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Language Settings Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, size: 32),
              title: Text(
                Translations.get('language', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LanguageSettingsPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
