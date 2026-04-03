import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/providers/localization_provider.dart';

class LanguageSettingsPage extends ConsumerStatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  ConsumerState<LanguageSettingsPage> createState() =>
      _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends ConsumerState<LanguageSettingsPage> {
  late String _selectedLanguage;
  late String _savedLanguage;

  @override
  void initState() {
    super.initState();
    final current = ref.read(localizationProvider).languageCode;
    _selectedLanguage = current;
    _savedLanguage = current;
  }

  bool get _hasChanges => _selectedLanguage != _savedLanguage;

  void _save() async {
    await ref
        .read(localizationProvider.notifier)
        .setLanguage(_selectedLanguage);
    if (mounted) {
      setState(() => _savedLanguage = _selectedLanguage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('saved_successfully', _selectedLanguage),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localizationProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          Translations.get('language', lang),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _hasChanges ? _save : null,
              style: TextButton.styleFrom(
                foregroundColor:
                    _hasChanges ? AppTheme.primaryOrange : AppTheme.neutral200,
              ),
              child: Text(
                Translations.get('save', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── App Language Section ───
            Text(
              Translations.get('app_language', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral500,
              ),
            ),
            const SizedBox(height: 12),
            _buildLanguageCard(flag: '🇬🇧', label: 'English', code: 'en'),
            const SizedBox(height: 10),
            _buildLanguageCard(flag: '🇱🇦', label: 'ພາສາລາວ', code: 'lo'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String flag,
    required String label,
    required String code,
  }) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrangeBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? AppTheme.primaryOrange : AppTheme.neutral700,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neutral300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
