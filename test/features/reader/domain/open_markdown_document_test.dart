import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/domain/entities/markdown_document.dart';
import 'package:markdown_reader/features/reader/domain/repositories/document_repository.dart';
import 'package:markdown_reader/features/reader/domain/usecases/open_markdown_document.dart';

class StubDocumentRepository implements DocumentRepository {
  @override
  Future<MarkdownDocument?> pickAndRead() async => const MarkdownDocument(
    fileName: 'example.md',
    content: '# Example',
    sizeInBytes: 9,
  );
}

void main() {
  test('delegates document loading to the repository contract', () async {
    final result = await OpenMarkdownDocument(StubDocumentRepository())();
    expect(result?.content, '# Example');
  });
}
