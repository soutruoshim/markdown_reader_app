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

  @override
  ReaderSettings build() {
    _loadSettings();
    return const ReaderSettings();
  }

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      final themeStr = prefs.getString(_keyTheme);
      final fontSize = prefs.getDouble(_keyFontSize);
      final keepOffline = prefs.getBool(_keyKeepOffline);
      final maxRecents = prefs.getInt(_keyMaxRecents);

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
    try {
      final prefs = await _getPrefs();
      final str = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system';
      await prefs?.setString(_keyTheme, str);
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
    try {
      final prefs = await _getPrefs();
      await prefs?.setDouble(_keyFontSize, size);
    } catch (_) {}
  }

  Future<void> setKeepOfflineCopies(bool keep) async {
    state = state.copyWith(keepOfflineCopies: keep);
    try {
      final prefs = await _getPrefs();
      await prefs?.setBool(_keyKeepOffline, keep);
    } catch (_) {}
  }

  Future<void> setMaxRecentFiles(int max) async {
    state = state.copyWith(maxRecentFiles: max);
    try {
      final prefs = await _getPrefs();
      await prefs?.setInt(_keyMaxRecents, max);
    } catch (_) {}
  }
}
