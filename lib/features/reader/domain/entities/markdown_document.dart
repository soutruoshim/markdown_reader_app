import 'dart:typed_data';

class MarkdownDocument {
  const MarkdownDocument({
    required this.fileName,
    required this.content,
    required this.sizeInBytes,
    this.filePath,
    this.rawBytes,
  });

  final String fileName;
  final String content;
  final int sizeInBytes;
  final String? filePath;
  final Uint8List? rawBytes;

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');
  bool get isDocx => fileName.toLowerCase().endsWith('.docx');
  bool get isMarkdown => !isPdf && !isDocx;
}

