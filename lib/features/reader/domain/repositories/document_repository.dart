import '../entities/markdown_document.dart';

abstract interface class DocumentRepository {
  /// Null means the user dismissed the native file picker.
  Future<MarkdownDocument?> pickAndRead();
}
