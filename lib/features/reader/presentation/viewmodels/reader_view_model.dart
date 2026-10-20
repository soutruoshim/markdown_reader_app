import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/document_failure.dart';
import '../../data/repositories/local_recent_documents_repository.dart';
import '../../di/reader_providers.dart';
import 'reader_state.dart';

final readerViewModelProvider = NotifierProvider<ReaderViewModel, ReaderState>(
  ReaderViewModel.new,
);

class ReaderViewModel extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    Future.microtask(() => refreshRecents());
    return const ReaderState();
  }

  Future<void> loadSampleDocuments() async {
    final repo = ref.read(recentDocumentsRepositoryProvider);
    if (repo is LocalRecentDocumentsRepository) {
      await repo.seedSampleDocuments();
      await refreshRecents();
    }
  }

  Future<void> refreshRecents() async {
    try {
      final recents = await ref.read(listRecentDocumentsProvider)();
      if (!ref.mounted) return;
      state = ReaderState(
        document: state.document,
        recentDocuments: recents,
        isLoading: state.isLoading,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: state.document,
        recentDocuments: state.recentDocuments,
        isLoading: state.isLoading,
        errorMessage: 'Could not load recent files.',
      );
    }
  }

  Future<void> openFile() async {
    if (state.isLoading) return;
    final previousDocument = state.document;
    final previousRecents = state.recentDocuments;
    state = ReaderState(
      document: previousDocument,
      recentDocuments: previousRecents,
      isLoading: true,
    );
    try {
      final document = await ref.read(openMarkdownDocumentProvider)();
      if (!ref.mounted) return;
      if (document == null) {
        state = ReaderState(
          document: previousDocument,
          recentDocuments: previousRecents,
        );
        return;
      }
      // Showing the document must not depend on saving to the recent index.
      state = ReaderState(document: document, recentDocuments: previousRecents);
      try {
        await ref.read(saveRecentDocumentProvider)(document);
        final recents = await ref.read(listRecentDocumentsProvider)();
        if (!ref.mounted) return;
        state = ReaderState(document: document, recentDocuments: recents);
      } catch (_) {
        if (!ref.mounted) return;
        state = ReaderState(
          document: document,
          recentDocuments: previousRecents,
          errorMessage: 'Opened file, but could not save it to Recent Files.',
        );
      }
    } on DocumentFailure catch (error) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: previousDocument,
        recentDocuments: previousRecents,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: previousDocument,
        recentDocuments: previousRecents,
        errorMessage: 'Unexpected error opening the document.',
      );
    }
  }

  Future<void> openRecent(String id) async {
    if (state.isLoading) return;
    final previousDocument = state.document;
    final previousRecents = state.recentDocuments;
    state = ReaderState(
      document: previousDocument,
      recentDocuments: previousRecents,
      isLoading: true,
    );
    try {
      final document = await ref.read(openRecentDocumentProvider)(id);
      final recents = await ref.read(listRecentDocumentsProvider)();
      if (!ref.mounted) return;
      state = ReaderState(document: document, recentDocuments: recents);
    } on DocumentFailure catch (error) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: previousDocument,
        recentDocuments: error is RecentDocumentMissingFailure
            ? previousRecents.where((e) => e.id != id).toList()
            : previousRecents,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: previousDocument,
        recentDocuments: previousRecents,
        errorMessage: 'Could not reopen this recent file.',
      );
    }
  }

  Future<void> removeRecent(String id) async {
    if (state.isLoading) return;
    try {
      await ref.read(removeRecentDocumentProvider)(id);
      await refreshRecents();
    } catch (_) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: state.document,
        recentDocuments: state.recentDocuments,
        errorMessage: 'Could not remove the recent file.',
      );
    }
  }

  Future<void> clearRecents() async {
    if (state.isLoading) return;
    try {
      await ref.read(clearRecentDocumentsProvider)();
      if (!ref.mounted) return;
      state = ReaderState(document: state.document);
    } catch (_) {
      if (!ref.mounted) return;
      state = ReaderState(
        document: state.document,
        recentDocuments: state.recentDocuments,
        errorMessage: 'Could not clear Recent Files.',
      );
    }
  }

  void closeDocument() {
    state = ReaderState(
      document: null,
      recentDocuments: state.recentDocuments,
      isLoading: false,
    );
  }
}
