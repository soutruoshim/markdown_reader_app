import 'dart:typed_data';

class PickedMarkdownData {
  const PickedMarkdownData({
    required this.name,
    required this.bytes,
    this.path,
  });

  final String name;
  final Uint8List bytes;
  final String? path;
}

abstract interface class MarkdownFileSource {
  Future<PickedMarkdownData?> pick();
}

