import 'dart:typed_data';

class PickedMarkdownData {
  const PickedMarkdownData({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

abstract interface class MarkdownFileSource {
  Future<PickedMarkdownData?> pick();
}
