import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/reader/presentation/views/reader_page.dart';
import '../features/settings/presentation/viewmodels/settings_view_model.dart';

class MarkdownReaderApp extends ConsumerWidget {
  const MarkdownReaderApp({super.key});

  static const primarySeed = Color(0xFF4355B9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);

    final lightTheme = ThemeData(
      colorSchemeSeed: primarySeed,
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0E7FF),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primarySeed);
          }
          return const IconThemeData(color: Color(0xFF6B7280));
        }),
      ),
    );

    final darkTheme = ThemeData(
      colorSchemeSeed: primarySeed,
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF13151A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF13151A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1D24),
        indicatorColor: const Color(0xFF2C3348),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF818CF8));
          }
          return const IconThemeData(color: Color(0xFF9CA3AF));
        }),
      ),
    );

    return MaterialApp(
      title: 'Markdown Reader',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const ReaderPage(),
    );
  }
}
