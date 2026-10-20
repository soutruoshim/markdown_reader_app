import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/presentation/views/reader_page.dart';

void main() {
  testWidgets('shows empty reader state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReaderPage())),
    );
    expect(find.text('Open Markdown file'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
  });
}
