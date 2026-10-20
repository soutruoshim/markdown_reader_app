import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/domain/entities/markdown_document.dart';
import 'package:markdown_reader/features/reader/presentation/views/markdown_reader_screen.dart';

void main() {
  const testDoc = MarkdownDocument(
    fileName: 'README.md',
    content:
        '# Getting Started\n\nWelcome to Markdown Reader.\n\nRead formatted Markdown files offline.',
    sizeInBytes: 85,
  );

  testWidgets(
    'renders MarkdownReaderScreen with header, content, and progress footer',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MarkdownReaderScreen(document: testDoc)),
        ),
      );

      // Verify Title and Icons
      expect(find.text('README.md'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Verify Reading Progress Footer
      expect(find.textContaining('Page 1 of'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Enter Search Mode
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify Search Bar and Done action
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Type to find matches'), findsOneWidget);

      // Type search query
      await tester.enterText(find.byType(TextField), 'Markdown');
      await tester.pumpAndSettle();

      // Verify match count strip
      expect(find.text('1 of 2 matches'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Step match
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2 matches'), findsOneWidget);

      // Exit search mode via Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('README.md'), findsOneWidget);
    },
  );
}
