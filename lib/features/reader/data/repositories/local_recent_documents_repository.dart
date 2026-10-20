import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import '../datasources/recent_index_store.dart';

import '../../../../core/errors/document_failure.dart';
import '../../domain/entities/markdown_document.dart';
import '../../domain/entities/recent_document.dart';
import '../../domain/repositories/recent_documents_repository.dart';

/// Stores recent-file *snapshots*, not unstable picker cache paths.
/// This implementation is for Android, iOS and desktop, not Flutter Web.
class LocalRecentDocumentsRepository implements RecentDocumentsRepository {
  LocalRecentDocumentsRepository({
    required this._indexStore,
    required this._applicationDirectory,
    this.maxEntries = 20,
    this.seedInitialSamples = false,
  });

  static const int _maxBytes = 2 * 1024 * 1024;
  static final RegExp _validId = RegExp(r'^[a-f0-9]{64}$');

  final RecentIndexStore _indexStore;
  final Future<Directory> Function() _applicationDirectory;
  final int maxEntries;
  final bool seedInitialSamples;

  Future<Directory> _snapshotDirectory() async {
    final root = await _applicationDirectory();
    final snapshots = Directory('${root.path}/markdown_recent_snapshots');
    if (!await snapshots.exists()) {
      await snapshots.create(recursive: true);
    }
    return snapshots;
  }

  Future<File> _snapshotFile(String id) async {
    if (!_validId.hasMatch(id)) {
      throw const RecentDocumentMissingFailure();
    }
    final directory = await _snapshotDirectory();
    return File('${directory.path}/$id.md');
  }

  Future<void> seedSampleDocuments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final samples = [
      (
        'README.md',
        '# Getting Started\n\nWelcome to **Markdown Reader**, a sleek, focused offline-first reader.\n\n## Features\n- **Offline First**: All documents are stored securely in local cache.\n- **Reading Progress**: Sticky page counter and reading progress bar.\n- **Find in Document**: Real-time query search with match navigation.\n- **Customizable**: Dark and light modes with dynamic text scaling.\n\nEnjoy reading your Markdown documents anywhere!',
        DateTime(now.year, now.month, now.day, 14, 45),
      ),
      (
        'Flutter_Architecture.md',
        '# Flutter Architecture Guide\n\nThis application is built following **Clean Architecture** and **MVVM** with Flutter Riverpod.\n\n## Architecture Layers\n\n| Layer | Responsibility | Components |\n|---|---|---|\n| **Presentation** | Views, widgets, state management | `Notifier`, `Widget` |\n| **Domain** | Business rules, use cases | `UseCase`, `Entity` |\n| **Data** | Data retrieval and persistence | `Repository`, `DataSource` |\n\n## Offline Strategy\nSnapshots are saved locally using SHA-256 hashes for fast reopening without picker permissions.',
        DateTime(now.year, now.month, now.day, 11, 20),
      ),
      (
        'API_Documentation.md',
        '# API Documentation & Contracts\n\nTechnical specifications for the offline Markdown Reader core interfaces.\n\n## Specifications\n- **Max File Size**: 2 MB\n- **Snapshot Format**: SHA-256 keyed `.md` files\n- **Max Recents**: 20 files (configurable in Settings)\n\n## Use Cases\n- `OpenMarkdownDocument`\n- `ListRecentDocuments`\n- `SaveRecentDocument`\n- `RemoveRecentDocument`\n- `ClearRecentDocuments`',
        DateTime(yesterday.year, yesterday.month, yesterday.day, 15, 30),
      ),
    ];

    final entries = <RecentDocument>[];
    for (final sample in samples) {
      final name = sample.$1;
      final content = sample.$2;
      final openedAt = sample.$3;
      final bytes = utf8.encode(content);
      final id = sha256.convert(utf8.encode('$name\u0000$content')).toString();
      final file = await _snapshotFile(id);
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
      }
      entries.add(
        RecentDocument(
          id: id,
          fileName: name,
          sizeInBytes: bytes.length,
          openedAt: openedAt.toUtc(),
        ),
      );
    }
    await _writeIndex(entries);
  }

  @override
  Future<List<RecentDocument>> list() async {
    final raw = await _indexStore.read();
    if (raw == null) {
      if (seedInitialSamples) {
        try {
          await seedSampleDocuments();
          return await list();
        } catch (_) {
          return [];
        }
      }
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid recent file index');
    }

    final entries = <RecentDocument>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final id = item['id'];
      final name = item['fileName'];
      final size = item['sizeInBytes'];
      final openedAt = item['openedAt'];
      if (id is! String ||
          !_validId.hasMatch(id) ||
          name is! String ||
          size is! int ||
          size < 0 ||
          openedAt is! String) {
        continue;
      }
      final timestamp = DateTime.tryParse(openedAt);
      if (timestamp == null) continue;
      entries.add(
        RecentDocument(
          id: id,
          fileName: name,
          sizeInBytes: size,
          openedAt: timestamp,
        ),
      );
    }
    entries.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return entries.take(maxEntries).toList(growable: false);
  }

  Future<void> _writeIndex(List<RecentDocument> entries) => _indexStore.write(
    jsonEncode([
      for (final entry in entries)
        {
          'id': entry.id,
          'fileName': entry.fileName,
          'sizeInBytes': entry.sizeInBytes,
          'openedAt': entry.openedAt.toUtc().toIso8601String(),
        },
    ]),
  );

  @override
  Future<RecentDocument> save(MarkdownDocument document) async {
    final bytes = utf8.encode(document.content);
    if (bytes.length > _maxBytes) throw const DocumentTooLargeFailure();

    // Identical filename + content points to the same offline snapshot.
    // Edited file content is saved as a new revision; no picker paths needed.
    final id = sha256
        .convert(utf8.encode('${document.fileName}\u0000${document.content}'))
        .toString();
    final file = await _snapshotFile(id);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes, flush: true);
    }

    final existing = await list();
    final recent = RecentDocument(
      id: id,
      fileName: document.fileName,
      sizeInBytes: bytes.length,
      openedAt: DateTime.now().toUtc(),
    );
    final ordered = [recent, ...existing.where((e) => e.id != id)];
    final kept = ordered.take(maxEntries).toList(growable: false);
    await _writeIndex(kept);

    // Remove old snapshots after the new index was successfully saved.
    for (final obsolete in ordered.skip(maxEntries)) {
      await _deleteSnapshot(obsolete.id);
    }
    return recent;
  }

  @override
  Future<MarkdownDocument> open(String id) async {
    final records = await list();
    RecentDocument? metadata;
    for (final record in records) {
      if (record.id == id) {
        metadata = record;
        break;
      }
    }
    if (metadata == null) throw const RecentDocumentMissingFailure();

    final file = await _snapshotFile(id);
    if (!await file.exists()) {
      await remove(id);
      throw const RecentDocumentMissingFailure();
    }
    try {
      if (await file.length() > _maxBytes) {
        throw const DocumentTooLargeFailure();
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) throw const DocumentTooLargeFailure();
      final content = utf8.decode(bytes, allowMalformed: false);
      final updated = RecentDocument(
        id: id,
        fileName: metadata.fileName,
        sizeInBytes: bytes.length,
        openedAt: DateTime.now().toUtc(),
      );
      await _writeIndex([updated, ...records.where((e) => e.id != id)]);
      return MarkdownDocument(
        fileName: metadata.fileName,
        content: content,
        sizeInBytes: bytes.length,
      );
    } on DocumentFailure {
      rethrow;
    } on FormatException {
      throw const InvalidEncodingFailure();
    } on FileSystemException {
      throw const RecentDocumentMissingFailure();
    }
  }

  Future<void> _deleteSnapshot(String id) async {
    final file = await _snapshotFile(id);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> remove(String id) async {
    final records = await list();
    await _writeIndex(records.where((e) => e.id != id).toList());
    await _deleteSnapshot(id);
  }

  @override
  Future<void> clear() async {
    final records = await list();
    await _writeIndex([]);
    for (final record in records) {
      await _deleteSnapshot(record.id);
    }
  }
}
