import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/file_picker_markdown_source.dart';
import '../data/datasources/markdown_file_source.dart';
import '../data/datasources/recent_index_store.dart';
import '../data/repositories/document_repository_impl.dart';
import '../data/repositories/local_recent_documents_repository.dart';
import '../domain/repositories/document_repository.dart';
import '../domain/repositories/recent_documents_repository.dart';
import '../domain/usecases/clear_recent_documents.dart';
import '../domain/usecases/list_recent_documents.dart';
import '../domain/usecases/open_markdown_document.dart';
import '../domain/usecases/open_recent_document.dart';
import '../domain/usecases/remove_recent_document.dart';
import '../domain/usecases/save_recent_document.dart';

final markdownFileSourceProvider = Provider<MarkdownFileSource>(
  (ref) => const FilePickerMarkdownSource(),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(ref.watch(markdownFileSourceProvider)),
);

final openMarkdownDocumentProvider = Provider<OpenMarkdownDocument>(
  (ref) => OpenMarkdownDocument(ref.watch(documentRepositoryProvider)),
);

final recentDocumentsRepositoryProvider = Provider<RecentDocumentsRepository>(
  (ref) => LocalRecentDocumentsRepository(
    indexStore: SharedPreferencesRecentIndexStore(SharedPreferencesAsync()),
    applicationDirectory: getApplicationSupportDirectory,
  ),
);

final listRecentDocumentsProvider = Provider<ListRecentDocuments>(
  (ref) => ListRecentDocuments(ref.watch(recentDocumentsRepositoryProvider)),
);
final saveRecentDocumentProvider = Provider<SaveRecentDocument>(
  (ref) => SaveRecentDocument(ref.watch(recentDocumentsRepositoryProvider)),
);
final openRecentDocumentProvider = Provider<OpenRecentDocument>(
  (ref) => OpenRecentDocument(ref.watch(recentDocumentsRepositoryProvider)),
);
final removeRecentDocumentProvider = Provider<RemoveRecentDocument>(
  (ref) => RemoveRecentDocument(ref.watch(recentDocumentsRepositoryProvider)),
);
final clearRecentDocumentsProvider = Provider<ClearRecentDocuments>(
  (ref) => ClearRecentDocuments(ref.watch(recentDocumentsRepositoryProvider)),
);
