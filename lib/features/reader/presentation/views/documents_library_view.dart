import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../domain/entities/recent_document.dart';
import '../viewmodels/reader_view_model.dart';
import '../widgets/file_actions_bottom_sheet.dart';
import 'markdown_reader_screen.dart';

class DocumentsLibraryView extends ConsumerStatefulWidget {
  const DocumentsLibraryView({super.key});

  @override
  ConsumerState<DocumentsLibraryView> createState() =>
      _DocumentsLibraryViewState();
}

class _DocumentsLibraryViewState extends ConsumerState<DocumentsLibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _seeAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(readerViewModelProvider.notifier).refreshRecents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatItemSubtitle(DateTime dt, int bytes) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $amPm';

    final sizeStr = _formatSize(bytes);

    if (isToday) {
      return '$timeStr • $sizeStr';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[local.month - 1];
    return '$monthStr ${local.day} • $sizeStr';
  }

  Map<String, List<RecentDocument>> _groupDocuments(
    List<RecentDocument> documents,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<RecentDocument>> grouped = {};

    for (final doc in documents) {
      final docDate = DateTime(
        doc.openedAt.year,
        doc.openedAt.month,
        doc.openedAt.day,
      );
      String group;
      if (docDate == today) {
        group = 'TODAY';
      } else if (docDate == yesterday) {
        group = 'YESTERDAY';
      } else {
        group = 'EARLIER';
      }
      grouped.putIfAbsent(group, () => []).add(doc);
    }

    return grouped;
  }

  Future<void> _openFilePicker() async {
    final viewModel = ref.read(readerViewModelProvider.notifier);
    final doc = await viewModel.openFile();
    if (!mounted || doc == null) return;
    await Navigator.of(context).push(MarkdownReaderScreen.route(doc));
    if (mounted) {
      viewModel.closeDocument();
    }
  }

  Future<void> _openRecentDocument(RecentDocument recent) async {
    final viewModel = ref.read(readerViewModelProvider.notifier);
    final doc = await viewModel.openRecent(recent.id);
    if (!mounted || doc == null) return;
    await Navigator.of(context).push(MarkdownReaderScreen.route(doc));
    if (mounted) {
      viewModel.closeDocument();
    }
  }

  (IconData, Color, Color, String) _getFileStyle(
    String fileName,
    bool isDark,
    Color defaultPrimary,
    Color defaultBg,
  ) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return (
        Icons.picture_as_pdf_outlined,
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        isDark ? const Color(0xFF3F1D20) : const Color(0xFFFEE2E2),
        'PDF',
      );
    } else if (lower.endsWith('.docx')) {
      return (
        Icons.article_outlined,
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        isDark ? const Color(0xFF1E2E4B) : const Color(0xFFDBEAFE),
        'DOCX',
      );
    }
    return (
      Icons.description_outlined,
      defaultPrimary,
      defaultBg,
      'MD',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE5E7EB);
    final iconBgColor = isDark
        ? const Color(0xFF2A3245)
        : const Color(0xFFEEF2FF);

    final allRecents = state.recentDocuments;
    final filteredRecents = _searchQuery.isEmpty
        ? allRecents
        : allRecents
              .where(
                (d) => d.fileName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    final isEmptyState = allRecents.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Markdown Reader',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => ref
                .read(settingsViewModelProvider.notifier)
                .toggleTheme(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 3,
            child: state.isLoading
                ? const LinearProgressIndicator(minHeight: 3)
                : const SizedBox.shrink(),
          ),
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: _openFilePicker,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(readerViewModelProvider.notifier).clearRecents(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                // Primary page heading: "My documents"
                Text(
                  isEmptyState ? 'Your reading space' : 'My documents',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                // Spacing: Main heading to subtitle (8dp)
                const SizedBox(height: 8),
                // Subtitle: 16sp, FontWeight.w400, onSurfaceVariant
                Text(
                  isEmptyState
                      ? 'Open a Markdown, Word, or PDF document and pick up right where you left off.'
                      : 'Pick up where you left off.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                // Spacing: Subtitle to Open Markdown File button (24dp)
                const SizedBox(height: 24),

                if (isEmptyState) ...[
                  // Wireframe 01: Large Empty Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nothing open yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select a .md, .docx, or .pdf file from your device',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Wireframe 01: Open Markdown File button
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('open-file-button'),
                      onPressed: state.isLoading ? null : _openFilePicker,
                      icon: const Icon(Icons.folder_open),
                      label: const Text(
                        'Open Markdown file',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF4F46E5)
                            : primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const Key('try-sample-button'),
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(readerViewModelProvider.notifier)
                              .loadSampleDocuments(),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: Text(
                        'Try sample documents',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE5E7EB) : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFE5E7EB) : primaryColor,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3F4555) : borderColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Wireframe 01: Recent files section
                  Text(
                    'Recent files',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2128)
                          : const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your recent documents appear here',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Available even after app restarts',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Wireframe 02: Open Markdown File primary button
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      key: const Key('open-file-button'),
                      onPressed: state.isLoading ? null : _openFilePicker,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Open Markdown File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF4F46E5)
                            : primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wireframe 02: Search recent files bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222630)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search recent files',
                              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                  ),

                  // Spacing: Search field → Recent files (32dp)
                  const SizedBox(height: 32),

                  // Wireframe 02: Section header with See all
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent files',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (allRecents.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _seeAll = !_seeAll;
                            });
                          },
                          child: Text(_seeAll ? 'Show less' : 'See all'),
                        ),
                    ],
                  ),
                  // Spacing: Recent files → TODAY (24dp)
                  const SizedBox(height: 24),

                  if (filteredRecents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No recent files match "$_searchQuery"',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Group documents by date (TODAY, YESTERDAY, EARLIER)
                    for (final (index, entry) in _groupDocuments(
                      _seeAll
                          ? filteredRecents
                          : filteredRecents.take(5).toList(),
                    ).entries.indexed) ...[
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 20,
                          bottom: 8,
                        ),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final recent in entry.value)
                        Padding(
                          // Spacing: Between file cards (12dp)
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openRecentDocument(recent),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final fileStyle = _getFileStyle(
                                        recent.fileName,
                                        isDark,
                                        primaryColor,
                                        iconBgColor,
                                      );
                                      return Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: fileStyle.$3,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          fileStyle.$1,
                                          color: fileStyle.$2,
                                          size: 22,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final fileStyle = _getFileStyle(
                                              recent.fileName,
                                              isDark,
                                              primaryColor,
                                              iconBgColor,
                                            );
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    recent.fileName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: fileStyle.$3,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    fileStyle.$4,
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      color: fileStyle.$2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _formatItemSubtitle(
                                            recent.openedAt,
                                            recent.sizeInBytes,
                                          ),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      FileActionsBottomSheet.show(
                                        context,
                                        recent,
                                        onOpenDocument: () =>
                                            _openRecentDocument(recent),
                                      );
                                    },
                                    tooltip: 'File options',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
