import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/settings/presentation/views/settings_view.dart';

void main() {
  testWidgets('renders SettingsView with all wireframe sections and controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsView())),
    );

    // Verify sections and titles
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Reading preferences'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);
    expect(find.text('Storage & history'), findsOneWidget);
    expect(find.text('Keep offline copies'), findsOneWidget);
    expect(find.text('Maximum recent files'), findsOneWidget);
    expect(find.text('Clear recent history'), findsOneWidget);
    expect(find.text('Markdown Reader · Version 1.0'), findsOneWidget);

    // Verify controls
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Adjust font size slider
    await tester.tap(find.byType(Slider));
    await tester.pump();

    // Toggle offline copies switch
    await tester.tap(find.byType(Switch));
    await tester.pump();
  });
}
