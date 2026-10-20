import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recent_document.dart';
import '../viewmodels/reader_view_model.dart';

class FileActionsBottomSheet extends ConsumerWidget {
  const FileActionsBottomSheet({
    super.key,
    required this.recent,
    required this.onOpenDocument,
  });

  final RecentDocument recent;
  final VoidCallback onOpenDocument;

  static Future<void> show(
    BuildContext context,
    RecentDocument recent, {
    required VoidCallback onOpenDocument,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FileActionsBottomSheet(
        recent: recent,
        onOpenDocument: onOpenDocument,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    final cardColor = isDark
        ? const Color(0xFF262B34)
        : const Color(0xFFF7F9FC);
    final iconBgColor = isDark
        ? const Color(0xFF323B4E)
        : const Color(0xFFEEF2FF);
    final primaryIconColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header title
              const Text(
                'File options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // File summary card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: primaryIconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recent.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved for offline reading • ${_formatSize(recent.sizeInBytes)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Option 1: Open document
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  Icons.chrome_reader_mode_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text(
                  'Open document',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenDocument();
                },
              ),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),

              // Option 2: Remove from recent files
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  Icons.history_toggle_off_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text(
                  'Remove from recent files',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(readerViewModelProvider.notifier)
                      .removeRecent(recent.id);
                },
              ),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),

              // Option 3: Delete offline copy
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete offline copy',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(readerViewModelProvider.notifier)
                      .removeRecent(recent.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
