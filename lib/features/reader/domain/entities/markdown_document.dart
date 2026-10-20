class MarkdownDocument {
  const MarkdownDocument({
    required this.fileName,
    required this.content,
    required this.sizeInBytes,
  });

  final String fileName;
  final String content;
  final int sizeInBytes;
}
