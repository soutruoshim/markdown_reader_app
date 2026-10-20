import '../repositories/recent_documents_repository.dart';

class RemoveRecentDocument {
  const RemoveRecentDocument(this._repository);
  final RecentDocumentsRepository _repository;

  Future<void> call(String id) => _repository.remove(id);
}
