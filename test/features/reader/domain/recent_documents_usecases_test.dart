import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/domain/entities/markdown_document.dart';
import 'package:markdown_reader/features/reader/domain/entities/recent_document.dart';
import 'package:markdown_reader/features/reader/domain/repositories/recent_documents_repository.dart';
import 'package:markdown_reader/features/reader/domain/usecases/list_recent_documents.dart';
import 'package:markdown_reader/features/reader/domain/usecases/open_recent_document.dart';
import 'package:markdown_reader/features/reader/domain/usecases/save_recent_document.dart';

class InMemoryRecentDocumentsRepository implements RecentDocumentsRepository {
  final Map<String, MarkdownDocument> documents = {};
  final List<RecentDocument> items = [];

  @override
  Future<List<RecentDocument>> list() async => List.of(items);

  @override
  Future<RecentDocument> save(MarkdownDocument document) async {
    final id = '${document.fileName}:${document.content}';
    documents[id] = document;
    items.removeWhere((entry) => entry.id == id);
    final result = RecentDocument(
      id: id,
      fileName: document.fileName,
      sizeInBytes: document.sizeInBytes,
      openedAt: DateTime.now(),
    );
    items.insert(0, result);
    return result;
  }

  @override
  Future<MarkdownDocument> open(String id) async => documents[id]!;

  @override
  Future<void> remove(String id) async {
    documents.remove(id);
    items.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> clear() async {
    documents.clear();
    items.clear();
  }
}

void main() {
  test(
    'saved Markdown can be found and reopened via recent use cases',
    () async {
      final repository = InMemoryRecentDocumentsRepository();
      const document = MarkdownDocument(
        fileName: 'guide.md',
        content: '# Guide',
        sizeInBytes: 7,
      );
      final saved = await SaveRecentDocument(repository)(document);
      final recent = await ListRecentDocuments(repository)();
      expect(recent.single.id, saved.id);
      final reopened = await OpenRecentDocument(repository)(saved.id);
      expect(reopened.content, '# Guide');
    },
  );
}
