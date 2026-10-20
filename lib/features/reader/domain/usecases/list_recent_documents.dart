import '../entities/recent_document.dart';
import '../repositories/recent_documents_repository.dart';

class ListRecentDocuments {
  const ListRecentDocuments(this._repository);
  final RecentDocumentsRepository _repository;

  Future<List<RecentDocument>> call() => _repository.list();
}
