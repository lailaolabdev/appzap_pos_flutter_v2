import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageKey = 'app_language';

class LocalizationState {
  final String languageCode;
  final Locale locale;

  LocalizationState({required this.languageCode})
    : locale = Locale(languageCode);

  LocalizationState copyWith({String? languageCode}) {
    return LocalizationState(languageCode: languageCode ?? this.languageCode);
  }
}

class LocalizationNotifier extends StateNotifier<LocalizationState> {
  LocalizationNotifier() : super(LocalizationState(languageCode: 'en'));

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_kLanguageKey) ?? 'en';
    state = LocalizationState(languageCode: savedLanguage);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, languageCode);
    state = LocalizationState(languageCode: languageCode);
  }

  /// Clear language preference (call on logout)
  Future<void> clearLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLanguageKey);
    state = LocalizationState(languageCode: 'en');
  }
}

final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, LocalizationState>(
      (ref) => LocalizationNotifier(),
    );
