import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_reader/features/reader/data/services/docx_to_markdown_converter.dart';

void main() {
  group('DocxToMarkdownConverter', () {
    test('converts document.xml with headings, bold, lists, and tables to markdown', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Heading1"/>
      </w:pPr>
      <w:r>
        <w:t>Project Overview</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>Bold intro</w:t>
      </w:r>
      <w:r>
        <w:t> and regular text.</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:numPr>
          <w:ilvl w:val="0"/>
        </w:numPr>
      </w:pPr>
      <w:r>
        <w:t>First bullet</w:t>
      </w:r>
    </w:p>
    <w:tbl>
      <w:tr>
        <w:tc><w:p><w:r><w:t>Header A</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>Header B</w:t></w:r></w:p></w:tc>
      </w:tr>
      <w:tr>
        <w:tc><w:p><w:r><w:t>Value 1</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>Value 2</w:t></w:r></w:p></w:tc>
      </w:tr>
    </w:tbl>
  </w:body>
</w:document>''';

      final archive = Archive();
      final xmlBytes = utf8.encode(xml);
      archive.addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);

      const converter = DocxToMarkdownConverter();
      final markdown = converter.convert(Uint8List.fromList(zipBytes));

      expect(markdown, contains('# Project Overview'));
      expect(markdown, contains('**Bold intro**'));
      expect(markdown, contains('- First bullet'));
      expect(markdown, contains('| Header A | Header B |'));
      expect(markdown, contains('| Value 1 | Value 2 |'));
    });
  });
}
