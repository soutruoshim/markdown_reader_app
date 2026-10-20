import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../../../core/errors/document_failure.dart';
import 'markdown_file_source.dart';

class FilePickerMarkdownSource implements MarkdownFileSource {
  const FilePickerMarkdownSource();

  static const int maxBytes = 2 * 1024 * 1024;

  @override
  Future<PickedMarkdownData?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown'],
    );
    if (file == null) return null;

    // Validate metadata when available, then enforce size while streaming.
    final declaredSize = file.lengthSync() ?? await file.length();
    if (declaredSize != null && declaredSize > maxBytes) {
      throw const DocumentTooLargeFailure();
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (builder.length + chunk.length > maxBytes) {
        throw const DocumentTooLargeFailure();
      }
      builder.add(chunk);
    }
    return PickedMarkdownData(name: file.name, bytes: builder.takeBytes());
  }
}
