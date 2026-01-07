import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../services/storage_service.dart';

class AppSettings {
  final String language;
  final ThemeMode themeMode;

  AppSettings({
    this.language = 'fr',
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    String? language,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  String get languageDisplayName {
    switch (language) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  String get themeDisplayName {
    switch (themeMode) {
      case ThemeMode.system:
        return 'Automatique';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  String get themeModeString {
    switch (themeMode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  static ThemeMode themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final language = _storage.getLocale();
    final themeString = _storage.getThemeMode();
    final themeMode = AppSettings.themeModeFromString(themeString);

    state = AppSettings(
      language: language,
      themeMode: themeMode,
    );
  }

  Future<void> setLanguage(String language) async {
    await _storage.setLocale(language);
    state = state.copyWith(language: language);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final themeString = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.setThemeMode(themeString);
    state = state.copyWith(themeMode: themeMode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});
