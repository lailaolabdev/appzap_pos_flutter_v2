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
  LocalizationNotifier() : super(LocalizationState(languageCode: 'en'));

  Future<void> loadFromStorage() async {
    final savedLanguage = await storage.read(key: 'app_language') ?? 'en';
    state = LocalizationState(languageCode: savedLanguage);
  }

  Future<void> setLanguage(String languageCode) async {
    await storage.write(key: 'app_language', value: languageCode);
    state = LocalizationState(languageCode: languageCode);
  }
}

final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, LocalizationState>(
      (ref) => LocalizationNotifier(),
    );
