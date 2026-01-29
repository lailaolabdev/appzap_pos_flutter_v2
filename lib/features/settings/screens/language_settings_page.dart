import '../../../app/theme.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/localization_provider.dart';

class LanguageSettingsPage extends ConsumerStatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  ConsumerState<LanguageSettingsPage> createState() =>
      _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends ConsumerState<LanguageSettingsPage> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(localizationProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final localization = ref.watch(localizationProvider);
    _selectedLanguage = localization.languageCode;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(Translations.get('language', localization.languageCode)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('language', localization.languageCode),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(
                              Translations.get(
                                'english',
                                localization.languageCode,
                              ),
                            ),
                            value: 'en',
                            groupValue: _selectedLanguage,
                            onChanged: (value) {
                              if (value != null) {
                                _changeLanguage(value);
                              }
                            },
                          ),
                          Divider(height: 1, color: AppTheme.neutral300),
                          RadioListTile<String>(
                            title: Text(
                              Translations.get(
                                'lao',
                                localization.languageCode,
                              ),
                            ),
                            value: 'lo',
                            groupValue: _selectedLanguage,
                            onChanged: (value) {
                              if (value != null) {
                                _changeLanguage(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    ref.read(localizationProvider.notifier).setLanguage(languageCode);
    setState(() => _selectedLanguage = languageCode);
  }
}
