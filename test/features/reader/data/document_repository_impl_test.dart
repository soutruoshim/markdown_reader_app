import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/core/errors/document_failure.dart';
import 'package:markdown_reader/features/reader/data/datasources/markdown_file_source.dart';
import 'package:markdown_reader/features/reader/data/repositories/document_repository_impl.dart';

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
}
