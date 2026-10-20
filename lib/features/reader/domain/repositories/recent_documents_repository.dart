import '../entities/markdown_document.dart';
import '../entities/recent_document.dart';

abstract interface class RecentDocumentsRepository {
  Future<List<RecentDocument>> list();
  Future<RecentDocument> save(MarkdownDocument document);
  Future<MarkdownDocument> open(String id);
  Future<void> remove(String id);
  Future<void> clear();
}
