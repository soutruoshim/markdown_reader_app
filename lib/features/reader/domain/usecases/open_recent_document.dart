import '../entities/markdown_document.dart';
import '../repositories/recent_documents_repository.dart';

class OpenRecentDocument {
  const OpenRecentDocument(this._repository);
  final RecentDocumentsRepository _repository;

  Future<MarkdownDocument> call(String id) => _repository.open(id);
}
