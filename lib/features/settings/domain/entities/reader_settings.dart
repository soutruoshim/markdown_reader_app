import 'package:flutter/material.dart';

class ReaderSettings {
  const ReaderSettings({
    this.themeMode = ThemeMode.system,
    this.fontSize = 16.0,
    this.keepOfflineCopies = true,
    this.maxRecentFiles = 20,
  });

  final ThemeMode themeMode;
  final double fontSize;
  final bool keepOfflineCopies;
  final int maxRecentFiles;

  ReaderSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    bool? keepOfflineCopies,
    int? maxRecentFiles,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      keepOfflineCopies: keepOfflineCopies ?? this.keepOfflineCopies,
      maxRecentFiles: maxRecentFiles ?? this.maxRecentFiles,
    );
  }
}
