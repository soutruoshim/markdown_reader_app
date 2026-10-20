/// Metadata for an offline snapshot of a previously opened Markdown file.
class RecentDocument {
  const RecentDocument({
    required this.id,
    required this.fileName,
    required this.sizeInBytes,
    required this.openedAt,
  });

  final String id;
  final String fileName;
  final int sizeInBytes;
  final DateTime openedAt;
}
