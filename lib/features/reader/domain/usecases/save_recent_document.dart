import '../entities/markdown_document.dart';
import '../entities/recent_document.dart';
import '../repositories/recent_documents_repository.dart';

class SaveRecentDocument {
  const SaveRecentDocument(this._repository);
  final RecentDocumentsRepository _repository;

  Future<RecentDocument> call(MarkdownDocument document) =>
      _repository.save(document);
}
