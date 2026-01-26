import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_shell.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/error_banner.dart';
import '../providers/settings_provider.dart';
import '../widgets/printer_settings_card.dart';
import '../widgets/receipt_settings_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
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
          title: const Text('Settings'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Printer', icon: Icon(Icons.print)),
              Tab(text: 'Receipt', icon: Icon(Icons.receipt)),
            ],
          ),
        ),
        body: Column(
          children: [
            if (settingsState.error != null)
              ErrorBanner(message: settingsState.error!),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrinterTab(settingsState, isMobile),
                  _buildReceiptTab(settingsState, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTab(SettingsState settingsState, bool isMobile) {
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Connection Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    settingsState.isPrinterConnected
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color:
                        settingsState.isPrinterConnected
                            ? AppTheme.success
                            : AppTheme.error,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settingsState.isPrinterConnected
                              ? 'Printer Connected'
                              : 'Printer Disconnected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settingsState.printerName.isNotEmpty
                              ? settingsState.printerName
                              : 'No printer configured',
                          style: TextStyle(color: AppTheme.neutral600),
                        ),
                      ],
                    ),
                  ),
                  if (settingsState.isPrinterConnected)
                    ElevatedButton(
                      onPressed:
                          () =>
                              ref
                                  .read(settingsProvider.notifier)
                                  .printTestReceipt(),
                      child: const Text('Test Print'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Printer Settings Card
          const PrinterSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildReceiptTab(SettingsState settingsState, bool isMobile) {
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(children: [ReceiptSettingsCard()]),
    );
  }
}
