import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../domain/entities/markdown_document.dart';

class MarkdownDocumentView extends StatelessWidget {
  const MarkdownDocumentView({
    super.key,
    required this.document,
    this.controller,
    this.fontSize = 16.0,
  });

  final MarkdownDocument document;
  final ScrollController? controller;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Markdown(
      key: ValueKey(document.fileName + document.content.hashCode.toString()),
      data: document.content,
      controller: controller,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h1: TextStyle(
          fontSize: fontSize * 1.65,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h2: TextStyle(
          fontSize: fontSize * 1.35,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        listBullet: TextStyle(fontSize: fontSize, color: primaryColor),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize * 0.9,
          backgroundColor: isDark
              ? const Color(0xFF2A2E39)
              : const Color(0xFFF1F3F5),
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
        ),
      ),
      imageBuilder: (uri, title, alt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '[Image not loaded: ${alt ?? uri.toString()}]',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
