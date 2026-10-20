import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/core/errors/document_failure.dart';
import 'package:markdown_reader/features/reader/data/datasources/markdown_file_source.dart';
import 'package:markdown_reader/features/reader/data/repositories/document_repository_impl.dart';
import 'package:markdown_reader/features/reader/data/repositories/local_recent_documents_repository.dart';

class FakeFileSource implements MarkdownFileSource {
  FakeFileSource(this.result);
  final PickedMarkdownData? result;

  @override
  Future<PickedMarkdownData?> pick() async => result;
}

void main() {
  test('reads valid UTF-8 Markdown', () async {
    final bytes = Uint8List.fromList(utf8.encode('# Hello'));
    final repository = DocumentRepositoryImpl(
      FakeFileSource(PickedMarkdownData(name: 'readme.md', bytes: bytes)),
    );
    final document = await repository.pickAndRead();
    expect(document?.fileName, 'readme.md');
    expect(document?.content, '# Hello');
  });

  test('returns null when user cancels selection', () async {
    final repository = DocumentRepositoryImpl(FakeFileSource(null));
    expect(await repository.pickAndRead(), isNull);
  });

  test('rejects incorrect file extension', () async {
    final repository = DocumentRepositoryImpl(
      FakeFileSource(
        PickedMarkdownData(name: 'notes.txt', bytes: Uint8List(0)),
      ),
    );
    expect(repository.pickAndRead(), throwsA(isA<UnsupportedFileFailure>()));
  });

  test('rejects malformed UTF-8', () async {
    final repository = DocumentRepositoryImpl(
      FakeFileSource(
        PickedMarkdownData(
          name: 'broken.md',
          bytes: Uint8List.fromList([0xc3, 0x28]),
        ),
      ),
    );
    expect(repository.pickAndRead(), throwsA(isA<InvalidEncodingFailure>()));
  });

  test('reads valid DOCX file and converts to Markdown', () async {
    final docxBytes = LocalRecentDocumentsRepository.createSampleDocx();
    final repository = DocumentRepositoryImpl(
      FakeFileSource(
        PickedMarkdownData(name: 'document.docx', bytes: docxBytes),
      ),
    );
    final document = await repository.pickAndRead();
    expect(document?.fileName, 'document.docx');
    expect(document?.isDocx, isTrue);
    expect(document?.content, contains('# Project Proposal'));
  });

  test('reads valid PDF file and preserves raw bytes', () async {
    final pdfBytes = LocalRecentDocumentsRepository.createSamplePdf();
    final repository = DocumentRepositoryImpl(
      FakeFileSource(
        PickedMarkdownData(
          name: 'document.pdf',
          bytes: pdfBytes,
          path: '/path/to/document.pdf',
        ),
      ),
    );
    final document = await repository.pickAndRead();
    expect(document?.fileName, 'document.pdf');
    expect(document?.isPdf, isTrue);
    expect(document?.rawBytes, equals(pdfBytes));
    expect(document?.filePath, '/path/to/document.pdf');
  });
}
