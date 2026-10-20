/// Domain-facing errors with safe, user-readable messages.
class DocumentFailure implements Exception {
  const DocumentFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class DocumentTooLargeFailure extends DocumentFailure {
  const DocumentTooLargeFailure()
    : super('File is too large. Maximum supported size is 2 MiB.');
}

class UnsupportedFileFailure extends DocumentFailure {
  const UnsupportedFileFailure()
    : super('Please choose a .md or .markdown file.');
}

class InvalidEncodingFailure extends DocumentFailure {
  const InvalidEncodingFailure() : super('File must contain valid UTF-8 text.');
}

class DocumentReadFailure extends DocumentFailure {
  const DocumentReadFailure()
    : super('Could not read this file. Try another document.');
}

class RecentDocumentMissingFailure extends DocumentFailure {
  const RecentDocumentMissingFailure()
    : super('This recent document is no longer available.');
}
