import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/data/datasources/recent_index_store.dart';
import 'package:markdown_reader/features/reader/data/repositories/local_recent_documents_repository.dart';
import 'package:markdown_reader/features/reader/domain/entities/markdown_document.dart';

class MemoryIndexStore implements RecentIndexStore {
  String? index;
  @override
  Future<String?> read() async => index;
  @override
  Future<void> write(String json) async {
    index = json;
  }
}

void main() {
  late Directory directory;
  late MemoryIndexStore metadata;
  late LocalRecentDocumentsRepository repo;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('markdown_recents_test_');
    metadata = MemoryIndexStore();
    repo = LocalRecentDocumentsRepository(
      indexStore: metadata,
      applicationDirectory: () async => directory,
      maxEntries: 3,
    );
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('save and reopen without original file or file picker', () async {
    const original = MarkdownDocument(
      fileName: 'guide.md',
      content: '# Guide',
      sizeInBytes: 7,
    );
    final saved = await repo.save(original);
    expect((await repo.list()).single.id, saved.id);

    // A newly created repository simulates app restart while preserving storage.
    final afterRestart = LocalRecentDocumentsRepository(
      indexStore: metadata,
      applicationDirectory: () async => directory,
    );
    final result = await afterRestart.open(saved.id);
    expect(result.content, '# Guide');
    expect(result.fileName, 'guide.md');
  });

  test(
    'duplicate content reuses one entry and cap evicts old snapshots',
    () async {
      const first = MarkdownDocument(
        fileName: 'a.md',
        content: '# A',
        sizeInBytes: 3,
      );
      final saved = await repo.save(first);
      await repo.save(first);
      expect((await repo.list()), hasLength(1));

      for (var n = 0; n < 3; n++) {
        await repo.save(
          MarkdownDocument(fileName: '$n.md', content: '# $n', sizeInBytes: 3),
        );
      }
      expect(await repo.list(), hasLength(3));
      final originalCopy = File(
        '${directory.path}/markdown_recent_snapshots/${saved.id}.md',
      );
      expect(await originalCopy.exists(), false);
    },
  );

  test('remove and clear delete private copies only', () async {
    final source = File('${directory.path}/original.md');
    await source.writeAsString('# Mine');
    final recent = await repo.save(
      const MarkdownDocument(
        fileName: 'original.md',
        content: '# Mine',
        sizeInBytes: 6,
      ),
    );
    final snapshot = File(
      '${directory.path}/markdown_recent_snapshots/${recent.id}.md',
    );
    expect(await snapshot.exists(), true);

    await repo.remove(recent.id);
    expect(await snapshot.exists(), false);
    expect(await source.exists(), true);
    await repo.save(
      const MarkdownDocument(
        fileName: 'original.md',
        content: '# Mine',
        sizeInBytes: 6,
      ),
    );
    await repo.clear();
    expect(await repo.list(), isEmpty);
    expect(await source.exists(), true);
  });

  test('seeds wireframe sample documents when enabled and index is empty', () async {
    final seededRepo = LocalRecentDocumentsRepository(
      indexStore: metadata,
      applicationDirectory: () async => directory,
      seedInitialSamples: true,
    );
    final recents = await seededRepo.list();
    expect(recents, hasLength(4));
    expect(
      recents.map((r) => r.fileName),
      containsAll([
        'README.md',
        'Project_Proposal.docx',
        'Offline_Guide.pdf',
        'API_Documentation.md',
      ]),
    );
  });
}
