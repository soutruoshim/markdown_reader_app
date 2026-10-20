import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reader_settings.dart';

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, ReaderSettings>(SettingsViewModel.new);

class SettingsViewModel extends Notifier<ReaderSettings> {
  static const _keyTheme = 'settings_theme_mode';
  static const _keyFontSize = 'settings_font_size';
  static const _keyKeepOffline = 'settings_keep_offline_copies';
  static const _keyMaxRecents = 'settings_max_recent_files';

  SharedPreferencesAsync? _prefs;

  @override
  ReaderSettings build() {
    try {
      _prefs = SharedPreferencesAsync();
      _loadSettings();
    } catch (_) {
      _prefs = null;
    }
    return const ReaderSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final themeStr = await prefs.getString(_keyTheme);
      final fontSize = await prefs.getDouble(_keyFontSize);
      final keepOffline = await prefs.getBool(_keyKeepOffline);
      final maxRecents = await prefs.getInt(_keyMaxRecents);

      ThemeMode theme = ThemeMode.system;
      if (themeStr == 'light') theme = ThemeMode.light;
      if (themeStr == 'dark') theme = ThemeMode.dark;

      state = state.copyWith(
        themeMode: theme,
        fontSize: fontSize ?? state.fontSize,
        keepOfflineCopies: keepOffline ?? state.keepOfflineCopies,
        maxRecentFiles: maxRecents ?? state.maxRecentFiles,
      );
    } catch (_) {
      // Keep defaults on unsupported environments/tests
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final str = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system';
      await prefs.setString(_keyTheme, str);
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    final nextMode = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setDouble(_keyFontSize, size);
    } catch (_) {}
  }

  Future<void> setKeepOfflineCopies(bool keep) async {
    state = state.copyWith(keepOfflineCopies: keep);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setBool(_keyKeepOffline, keep);
    } catch (_) {}
  }

  Future<void> setMaxRecentFiles(int max) async {
    state = state.copyWith(maxRecentFiles: max);
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setInt(_keyMaxRecents, max);
    } catch (_) {}
  }
}
