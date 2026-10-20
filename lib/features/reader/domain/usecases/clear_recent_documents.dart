import '../repositories/recent_documents_repository.dart';

class ClearRecentDocuments {
  const ClearRecentDocuments(this._repository);
  final RecentDocumentsRepository _repository;

  Future<void> call() => _repository.clear();
}
