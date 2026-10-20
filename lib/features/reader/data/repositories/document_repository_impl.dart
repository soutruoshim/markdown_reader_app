import 'dart:convert';
import '../../../../core/errors/document_failure.dart';
import '../../domain/entities/markdown_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/markdown_file_source.dart';
import '../services/docx_to_markdown_converter.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  const DocumentRepositoryImpl(this._source);
  final MarkdownFileSource _source;

  @override
  Future<MarkdownDocument?> pickAndRead() async {
    try {
      final picked = await _source.pick();
      if (picked == null) return null;

      final lowerName = picked.name.toLowerCase();
      final isMd = lowerName.endsWith('.md') || lowerName.endsWith('.markdown');
      final isDocx = lowerName.endsWith('.docx');
      final isPdf = lowerName.endsWith('.pdf');

      if (!isMd && !isDocx && !isPdf) {
        throw const UnsupportedFileFailure();
      }

      String content = '';
      if (isMd) {
        content = utf8.decode(picked.bytes, allowMalformed: false);
      } else if (isDocx) {
        content = const DocxToMarkdownConverter().convert(picked.bytes);
      }

      return MarkdownDocument(
        fileName: picked.name,
        content: content,
        sizeInBytes: picked.bytes.length,
        filePath: picked.path,
        rawBytes: picked.bytes,
      );
    } on DocumentFailure {
      rethrow;
    } on FormatException {
      throw const InvalidEncodingFailure();
    } catch (_) {
      throw const DocumentReadFailure();
    }
  }
}
