import 'dart:convert';
import '../../../../core/errors/document_failure.dart';
import '../../domain/entities/markdown_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/markdown_file_source.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  const DocumentRepositoryImpl(this._source);
  final MarkdownFileSource _source;

  @override
  Future<MarkdownDocument?> pickAndRead() async {
    try {
      final picked = await _source.pick();
      if (picked == null) return null;

      final lowerName = picked.name.toLowerCase();
      if (!lowerName.endsWith('.md') && !lowerName.endsWith('.markdown')) {
        throw const UnsupportedFileFailure();
      }

      final text = utf8.decode(picked.bytes, allowMalformed: false);
      return MarkdownDocument(
        fileName: picked.name,
        content: text,
        sizeInBytes: picked.bytes.length,
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
