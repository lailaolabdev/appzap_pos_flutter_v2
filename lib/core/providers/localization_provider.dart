import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

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
  LocalizationNotifier() : super(LocalizationState(languageCode: 'en')) {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final savedLanguage = await storage.read(key: 'app_language') ?? 'en';
      state = state.copyWith(languageCode: savedLanguage);
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await storage.write(key: 'app_language', value: languageCode);
      state = state.copyWith(languageCode: languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  String getLanguageCode() => state.languageCode;
  Locale getLocale() => state.locale;
}

final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, LocalizationState>(
      (ref) => LocalizationNotifier(),
    );
