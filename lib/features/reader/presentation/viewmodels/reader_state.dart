import '../../domain/entities/markdown_document.dart';
import '../../domain/entities/recent_document.dart';

class ReaderState {
  const ReaderState({
    this.document,
    this.recentDocuments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final MarkdownDocument? document;
  final List<RecentDocument> recentDocuments;
  final bool isLoading;
  final String? errorMessage;
}
