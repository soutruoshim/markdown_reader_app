import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../datasources/recent_index_store.dart';
import '../services/docx_to_markdown_converter.dart';

import '../../../../core/errors/document_failure.dart';
import '../../domain/entities/markdown_document.dart';
import '../../domain/entities/recent_document.dart';
import '../../domain/repositories/recent_documents_repository.dart';

/// Stores recent-file *snapshots*, not unstable picker cache paths.
/// Supports Markdown (.md), Microsoft Word (.docx), and PDF (.pdf).
class LocalRecentDocumentsRepository implements RecentDocumentsRepository {
  LocalRecentDocumentsRepository({
    required this.indexStore,
    required this.applicationDirectory,
    this.maxEntries = 20,
    this.seedInitialSamples = false,
  });

  static const int _maxBytes = 25 * 1024 * 1024;
  static final RegExp _validId = RegExp(r'^[a-f0-9]{64}$');

  final RecentIndexStore indexStore;
  final Future<Directory> Function() applicationDirectory;
  final int maxEntries;
  final bool seedInitialSamples;

  Future<Directory> _snapshotDirectory() async {
    final root = await applicationDirectory();
    final snapshots = Directory('${root.path}/markdown_recent_snapshots');
    if (!await snapshots.exists()) {
      await snapshots.create(recursive: true);
    }
    return snapshots;
  }

  Future<File> _snapshotFile(String id, [String? extension]) async {
    if (!_validId.hasMatch(id)) {
      throw const RecentDocumentMissingFailure();
    }
    final directory = await _snapshotDirectory();
    if (extension != null) {
      return File('${directory.path}/$id$extension');
    }
    for (final ext in const ['.md', '.pdf', '.docx', '.bin']) {
      final f = File('${directory.path}/$id$ext');
      if (await f.exists()) return f;
    }
    return File('${directory.path}/$id.md');
  }

  /// Creates a valid single-page sample PDF file.
  static Uint8List createSamplePdf() {
    const pdf = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 75 >>
stream
BT
/F1 22 Tf
50 720 Td
(Offline Document Reader - PDF Support) Tj
ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000244 00000 n 
0000000370 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
444
%%EOF''';
    return Uint8List.fromList(utf8.encode(pdf));
  }

  /// Creates a valid sample .docx ZIP archive containing document.xml.
  static Uint8List createSampleDocx() {
    const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>Project Proposal &amp; Specs</w:t></w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/></w:rPr>
        <w:t>Overview: </w:t>
      </w:r>
      <w:r>
        <w:t>This Word document (.docx) was parsed directly in offline reader mode.</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr><w:numPr><w:ilvl w:val="0"/></w:numPr></w:pPr>
      <w:r><w:t>Fast and responsive offline caching</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:numPr><w:ilvl w:val="0"/></w:numPr></w:pPr>
      <w:r><w:t>Full support for Dark and Light themes</w:t></w:r>
    </w:p>
    <w:tbl>
      <w:tr>
        <w:tc><w:p><w:r><w:t>Format</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>Supported Engine</w:t></w:r></w:p></w:tc>
      </w:tr>
      <w:tr>
        <w:tc><w:p><w:r><w:t>DOCX</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>Word-to-Markdown Engine</w:t></w:r></w:p></w:tc>
      </w:tr>
      <w:tr>
        <w:tc><w:p><w:r><w:t>PDF</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>PDFium Native Renderer</w:t></w:r></w:p></w:tc>
      </w:tr>
    </w:tbl>
  </w:body>
</w:document>''';

    final archive = Archive();
    final xmlBytes = utf8.encode(xml);
    archive.addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  Future<void> seedSampleDocuments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final docxBytes = createSampleDocx();
    final pdfBytes = createSamplePdf();

    final samples = [
      (
        'README.md',
        utf8.encode(
          '# Getting Started\n\nWelcome to **Markdown Reader**, a sleek, focused offline-first reader.\n\n## Features\n- **Offline First**: All documents are stored securely in local cache.\n- **Multi-Format**: Supports **Markdown (.md)**, **Word (.docx)**, and **PDF (.pdf)**.\n- **Reading Progress**: Sticky page counter and reading progress bar.\n- **Find in Document**: Real-time query search with match navigation.\n- **Customizable**: Dark and light modes with dynamic text scaling.\n\nEnjoy reading anywhere!',
        ),
        DateTime(now.year, now.month, now.day, 14, 45),
        '.md',
      ),
      (
        'Project_Proposal.docx',
        docxBytes,
        DateTime(now.year, now.month, now.day, 12, 15),
        '.docx',
      ),
      (
        'Offline_Guide.pdf',
        pdfBytes,
        DateTime(now.year, now.month, now.day, 11, 20),
        '.pdf',
      ),
      (
        'API_Documentation.md',
        utf8.encode(
          '# API Documentation & Contracts\n\nTechnical specifications for the offline Reader core interfaces.\n\n## Specifications\n- **Supported Formats**: Markdown (.md), Word (.docx), PDF (.pdf)\n- **Max File Size**: 25 MB\n- **Snapshot Format**: SHA-256 keyed cache files\n- **Max Recents**: 20 files (configurable in Settings)\n\n## Use Cases\n- `OpenMarkdownDocument`\n- `ListRecentDocuments`\n- `SaveRecentDocument`\n- `RemoveRecentDocument`\n- `ClearRecentDocuments`',
        ),
        DateTime(yesterday.year, yesterday.month, yesterday.day, 15, 30),
        '.md',
      ),
    ];

    final entries = <RecentDocument>[];
    for (final sample in samples) {
      final name = sample.$1;
      final bytes = sample.$2;
      final openedAt = sample.$3;
      final ext = sample.$4;
      final id = sha256.convert(utf8.encode('$name\u0000${bytes.length}')).toString();
      final file = await _snapshotFile(id, ext);
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
    final raw = await indexStore.read();
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

  Future<void> _writeIndex(List<RecentDocument> entries) => indexStore.write(
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
    final bytes = document.rawBytes ?? utf8.encode(document.content);
    if (bytes.length > _maxBytes) throw const DocumentTooLargeFailure();

    final ext = document.isPdf
        ? '.pdf'
        : (document.isDocx ? '.docx' : '.md');
    final id = sha256
        .convert(utf8.encode(
            '${document.fileName}\u0000${document.content.isNotEmpty ? document.content : bytes.length}'))
        .toString();
    final file = await _snapshotFile(id, ext);
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

      final lowerName = metadata.fileName.toLowerCase();
      final isPdf = lowerName.endsWith('.pdf');
      final isDocx = lowerName.endsWith('.docx');

      String content = '';
      if (isPdf) {
        content = '';
      } else if (isDocx) {
        content = const DocxToMarkdownConverter().convert(bytes);
      } else {
        content = utf8.decode(bytes, allowMalformed: false);
      }

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
        filePath: file.path,
        rawBytes: bytes,
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
    if (!_validId.hasMatch(id)) return;
    final directory = await _snapshotDirectory();
    for (final ext in const ['.md', '.pdf', '.docx', '.bin']) {
      final f = File('${directory.path}/$id$ext');
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
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
