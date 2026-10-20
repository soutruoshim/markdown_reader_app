import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/domain/entities/markdown_document.dart';
import 'package:markdown_reader/features/reader/domain/entities/recent_document.dart';
import 'package:markdown_reader/features/reader/domain/repositories/document_repository.dart';
import 'package:markdown_reader/features/reader/domain/repositories/recent_documents_repository.dart';
import 'package:markdown_reader/features/reader/presentation/viewmodels/reader_state.dart';
import 'package:markdown_reader/features/reader/presentation/viewmodels/reader_view_model.dart';
import 'package:markdown_reader/features/reader/presentation/views/documents_library_view.dart';
import 'package:markdown_reader/features/reader/presentation/views/markdown_reader_screen.dart';

class FakeRecentRepo implements RecentDocumentsRepository {
  List<RecentDocument> docs = [];
  @override
  Future<void> clear() async => docs.clear();
  @override
  Future<List<RecentDocument>> list() async => docs;
  @override
  Future<MarkdownDocument> open(String id) async => const MarkdownDocument(
    fileName: 'README.md',
    content: '# Content',
    sizeInBytes: 9,
  );
  @override
  Future<void> remove(String id) async => docs.removeWhere((d) => d.id == id);
  @override
  Future<RecentDocument> save(MarkdownDocument document) async {
    final recent = RecentDocument(
      id: 'abc',
      fileName: document.fileName,
      sizeInBytes: document.sizeInBytes,
      openedAt: DateTime.now(),
    );
    docs.add(recent);
    return recent;
  }
}

class FakeDocRepo implements DocumentRepository {
  @override
  Future<MarkdownDocument?> pickAndRead() async => const MarkdownDocument(
    fileName: 'Sample.md',
    content: '# Sample',
    sizeInBytes: 8,
  );
}

void main() {
  testWidgets('renders Empty State (Wireframe 01)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        readerViewModelProvider.overrideWith(
          () => _PreloadedReaderViewModel([]),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DocumentsLibraryView()),
      ),
    );

    expect(find.text('Markdown Reader'), findsOneWidget);
    expect(find.text('Your reading space'), findsOneWidget);
    expect(find.text('Nothing open yet'), findsOneWidget);
    expect(find.text('Open Markdown file'), findsOneWidget);
    expect(find.text('Recent files'), findsOneWidget);
    expect(find.text('Your recent documents appear here'), findsOneWidget);
    expect(find.text('Try sample documents'), findsOneWidget);
  });

  testWidgets(
    'renders Populated State and File Actions Bottom Sheet (Wireframes 02 & 05)',
    (tester) async {
      final recent = RecentDocument(
        id: 'doc-1',
        fileName: 'README.md',
        sizeInBytes: 8192,
        openedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          readerViewModelProvider.overrideWith(
            () => _PreloadedReaderViewModel([recent]),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DocumentsLibraryView()),
        ),
      );

      // Verify Populated view elements
      expect(find.text('My documents'), findsOneWidget);
      expect(find.text('Pick up where you left off.'), findsOneWidget);
      expect(find.text('Search recent files'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('README.md'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Open File Actions Bottom Sheet (Wireframe 05)
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('File options'), findsOneWidget);
      expect(find.text('Open document'), findsOneWidget);
      expect(find.text('Remove from recent files'), findsOneWidget);
      expect(find.text('Delete offline copy'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping document navigates smoothly to MarkdownReaderScreen with proper heading hierarchy',
    (tester) async {
      final recent = RecentDocument(
        id: 'doc-1',
        fileName: 'README.md',
        sizeInBytes: 8192,
        openedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          readerViewModelProvider.overrideWith(
            () => _PreloadedReaderViewModel([recent]),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DocumentsLibraryView()),
        ),
      );

      // Verify "My documents" is the primary heading (28sp, FontWeight.w600)
      final headingText = tester.widget<Text>(find.text('My documents'));
      expect(headingText.style?.fontSize, 28);
      expect(headingText.style?.fontWeight, FontWeight.w600);

      // Verify subtitle "Pick up where you left off." (16sp, FontWeight.w400)
      final subtitle =
          tester.widget<Text>(find.text('Pick up where you left off.'));
      expect(subtitle.style?.fontSize, 16);
      expect(subtitle.style?.fontWeight, FontWeight.w400);

      // Tap document tile to trigger navigation
      await tester.tap(find.text('README.md'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Verify reader screen reached smoothly
      expect(find.byType(MarkdownReaderScreen), findsOneWidget);
    },
  );
}

class _PreloadedReaderViewModel extends ReaderViewModel {
  _PreloadedReaderViewModel(this._initialRecents);
  final List<RecentDocument> _initialRecents;

  @override
  ReaderState build() => ReaderState(recentDocuments: _initialRecents);

  @override
  Future<void> refreshRecents() async {}

  @override
  Future<MarkdownDocument?> openRecent(String id) async {
    return const MarkdownDocument(
      fileName: 'README.md',
      content: '# Hello from Reader',
      sizeInBytes: 20,
    );
  }
}

