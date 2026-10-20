import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Converts a Microsoft Word (.docx) document into GitHub Flavored Markdown.
class DocxToMarkdownConverter {
  const DocxToMarkdownConverter();

  /// Converts raw .docx bytes into a Markdown formatted string.
  String convert(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? documentXmlFile;

      for (final file in archive) {
        if (file.name == 'word/document.xml' ||
            file.name.endsWith('/document.xml') ||
            file.name == 'document.xml') {
          documentXmlFile = file;
          break;
        }
      }

      if (documentXmlFile == null) {
        return _fallbackExtractAllText(archive);
      }

      final contentBytes = documentXmlFile.content as List<int>;
      final xmlString = utf8.decode(contentBytes, allowMalformed: true);
      return _parseDocumentXml(xmlString);
    } catch (_) {
      // Fallback: Attempt plain-text extraction if structured XML parsing fails
      return '# Document\n\n*Unable to fully parse .docx structure.*';
    }
  }

  String _parseDocumentXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final body = document.findAllElements('w:body').firstOrNull;
    if (body == null) return '';

    final buffer = StringBuffer();

    for (final child in body.children) {
      if (child is! XmlElement) continue;

      if (child.name.local == 'p') {
        final paragraphMd = _parseParagraph(child);
        if (paragraphMd.trim().isNotEmpty) {
          buffer.writeln(paragraphMd);
          buffer.writeln();
        }
      } else if (child.name.local == 'tbl') {
        final tableMd = _parseTable(child);
        if (tableMd.trim().isNotEmpty) {
          buffer.writeln(tableMd);
          buffer.writeln();
        }
      }
    }

    return buffer.toString().trim();
  }

  String _parseParagraph(XmlElement paragraph) {
    final pPr = paragraph.findElements('w:pPr').firstOrNull;
    String prefix = '';

    if (pPr != null) {
      final pStyle = pPr.findElements('w:pStyle').firstOrNull;
      final styleVal = pStyle?.getAttribute('w:val')?.toLowerCase() ?? '';

      if (styleVal.contains('heading1') ||
          styleVal.contains('heading 1') ||
          styleVal == 'title') {
        prefix = '# ';
      } else if (styleVal.contains('heading2') ||
          styleVal.contains('heading 2') ||
          styleVal == 'subtitle') {
        prefix = '## ';
      } else if (styleVal.contains('heading3') ||
          styleVal.contains('heading 3')) {
        prefix = '### ';
      } else if (styleVal.contains('heading4') ||
          styleVal.contains('heading 4')) {
        prefix = '#### ';
      } else if (styleVal.contains('heading5') ||
          styleVal.contains('heading 5')) {
        prefix = '##### ';
      } else if (styleVal.contains('heading6') ||
          styleVal.contains('heading 6')) {
        prefix = '###### ';
      }

      final numPr = pPr.findElements('w:numPr').firstOrNull;
      if (numPr != null && prefix.isEmpty) {
        prefix = '- ';
      }
    }

    final textBuffer = StringBuffer();

    for (final node in paragraph.children) {
      if (node is! XmlElement) continue;

      if (node.name.local == 'r') {
        textBuffer.write(_parseRun(node));
      } else if (node.name.local == 'hyperlink') {
        final linkText = StringBuffer();
        for (final run in node.findElements('w:r')) {
          linkText.write(_parseRun(run));
        }
        textBuffer.write(linkText.toString());
      }
    }

    final rawText = textBuffer.toString();
    if (rawText.trim().isEmpty) return '';

    return '$prefix$rawText';
  }

  String _parseRun(XmlElement run) {
    final rPr = run.findElements('w:rPr').firstOrNull;
    bool isBold = false;
    bool isItalic = false;
    bool isStrike = false;

    if (rPr != null) {
      final b = rPr.findElements('w:b').firstOrNull;
      if (b != null && b.getAttribute('w:val') != 'false') {
        isBold = true;
      }
      final i = rPr.findElements('w:i').firstOrNull;
      if (i != null && i.getAttribute('w:val') != 'false') {
        isItalic = true;
      }
      final strike = rPr.findElements('w:strike').firstOrNull;
      if (strike != null && strike.getAttribute('w:val') != 'false') {
        isStrike = true;
      }
    }

    final textBuffer = StringBuffer();
    for (final child in run.children) {
      if (child is! XmlElement) continue;
      if (child.name.local == 't') {
        textBuffer.write(child.innerText);
      } else if (child.name.local == 'br') {
        textBuffer.write('\n');
      } else if (child.name.local == 'tab') {
        textBuffer.write('    ');
      }
    }

    String result = textBuffer.toString();
    if (result.isEmpty) return '';

    if (isBold && isItalic) {
      result = '***$result***';
    } else if (isBold) {
      result = '**$result**';
    } else if (isItalic) {
      result = '*$result*';
    }

    if (isStrike) {
      result = '~~$result~~';
    }

    return result;
  }

  String _parseTable(XmlElement table) {
    final rows = table.findElements('w:tr').toList();
    if (rows.isEmpty) return '';

    final tableLines = <List<String>>[];

    for (final row in rows) {
      final cells = row.findElements('w:tc').toList();
      final rowCells = <String>[];
      for (final cell in cells) {
        final cellBuffer = StringBuffer();
        for (final p in cell.findElements('w:p')) {
          final pText = _parseParagraph(p).replaceAll('\n', ' ');
          if (pText.trim().isNotEmpty) {
            if (cellBuffer.isNotEmpty) cellBuffer.write(' ');
            cellBuffer.write(pText.trim());
          }
        }
        rowCells.add(cellBuffer.toString().replaceAll('|', '\\|'));
      }
      if (rowCells.isNotEmpty) {
        tableLines.add(rowCells);
      }
    }

    if (tableLines.isEmpty) return '';

    // Max column count
    int maxCols = 0;
    for (final line in tableLines) {
      if (line.length > maxCols) maxCols = line.length;
    }

    final buffer = StringBuffer();

    // Header row
    final header = tableLines.first;
    while (header.length < maxCols) {
      header.add('');
    }
    buffer.writeln('| ${header.join(' | ')} |');

    // Separator row
    final separator = List.filled(maxCols, '---');
    buffer.writeln('| ${separator.join(' | ')} |');

    // Body rows
    for (int i = 1; i < tableLines.length; i++) {
      final row = tableLines[i];
      while (row.length < maxCols) {
        row.add('');
      }
      buffer.writeln('| ${row.join(' | ')} |');
    }

    return buffer.toString();
  }

  String _fallbackExtractAllText(Archive archive) {
    final buffer = StringBuffer();
    for (final file in archive) {
      if (file.name.endsWith('.xml')) {
        try {
          final xmlStr = utf8.decode(file.content as List<int>, allowMalformed: true);
          final doc = XmlDocument.parse(xmlStr);
          for (final t in doc.findAllElements('w:t')) {
            buffer.write('${t.innerText} ');
          }
        } catch (_) {}
      }
    }
    return buffer.toString().trim();
  }
}
