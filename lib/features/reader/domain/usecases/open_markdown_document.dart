import '../entities/markdown_document.dart';
import '../repositories/document_repository.dart';

class OpenMarkdownDocument {
  const OpenMarkdownDocument(this._repository);

  final DocumentRepository _repository;

  Future<MarkdownDocument?> call() => _repository.pickAndRead();
}
