import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../domain/entities/markdown_document.dart';

class MarkdownReaderScreen extends ConsumerStatefulWidget {
  const MarkdownReaderScreen({super.key, required this.document});

  final MarkdownDocument document;

  static Route<void> route(MarkdownDocument document) {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/reader'),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          MarkdownReaderScreen(document: document),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<MarkdownReaderScreen> createState() =>
      _MarkdownReaderScreenState();
}

class _MarkdownReaderScreenState extends ConsumerState<MarkdownReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  PdfViewerController? _pdfController;

  bool _isSearching = false;
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  double _readingProgress = 0.0;
  int _currentPage = 1;
  late int _totalPages;

  @override
  void initState() {
    super.initState();
    if (widget.document.isPdf) {
      _pdfController = PdfViewerController();
      _totalPages = 1;
    } else {
      _totalPages = (widget.document.content.length / 1200).ceil().clamp(1, 99);
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (!widget.document.isPdf) {
      _scrollController.removeListener(_onScroll);
      _scrollController.dispose();
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      final page = ((progress * (_totalPages - 1)) + 1).round().clamp(
        1,
        _totalPages,
      );
      setState(() {
        _readingProgress = progress;
        _currentPage = page;
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _totalMatches = 0;
      _currentMatchIndex = 0;
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _totalMatches = 0;
        _currentMatchIndex = 0;
      });
      return;
    }

    final lowerContent = widget.document.content.toLowerCase();
    final lowerQuery = trimmed.toLowerCase();
    final matches = lowerQuery.allMatches(lowerContent).length;

    setState(() {
      _searchQuery = trimmed;
      _totalMatches = matches;
      _currentMatchIndex = matches > 0 ? 0 : 0;
    });
  }

  void _nextMatch() {
    if (_totalMatches == 0) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
    });
  }

  void _prevMatch() {
    if (_totalMatches == 0) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
    });
  }

  String _getProcessedContent() {
    if (!_isSearching || _searchQuery.isEmpty) {
      return widget.document.content;
    }

    // Highlight search query matches using ~~match~~ mapped to custom yellow background
    final regex = RegExp(RegExp.escape(_searchQuery), caseSensitive: false);
    return widget.document.content.replaceAllMapped(regex, (match) {
      return '~~${match.group(0)}~~';
    });
  }

  void _showDocumentDetails() {
    final formatName = widget.document.isPdf
        ? 'PDF Document (.pdf)'
        : (widget.document.isDocx
            ? 'Word Document (.docx)'
            : 'Markdown Document (.md)');
    final sizeKb = (widget.document.sizeInBytes / 1024).toStringAsFixed(1);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.document.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format: $formatName'),
            const SizedBox(height: 8),
            Text('Size: $sizeKb KB (${widget.document.sizeInBytes} bytes)'),
            const SizedBox(height: 8),
            if (widget.document.isPdf)
              Text('Pages: $_totalPages')
            else
              Text('Characters: ${widget.document.content.length}'),
            const SizedBox(height: 8),
            const Text('Mode: Offline reader'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final footerBgColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    final footerBorderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE5E7EB);
    final matchStripBg = isDark
        ? const Color(0xFF232A3B)
        : const Color(0xFFEEF2FF);

    final baseFontSize = settings.fontSize;

    return Scaffold(
        appBar: _isSearching
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitSearch,
                ),
                title: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2E39)
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Search in document',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: const Icon(Icons.close, size: 18),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _exitSearch,
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Container(
                    height: 40,
                    color: matchStripBg,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _totalMatches > 0
                              ? '${_currentMatchIndex + 1} of $_totalMatches matches'
                              : (_searchQuery.isEmpty
                                    ? 'Type to find matches'
                                    : 'No matches found'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_up,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _totalMatches > 0 ? _prevMatch : null,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _totalMatches > 0 ? _nextMatch : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: Text(
                  widget.document.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showDocumentDetails,
                    tooltip: 'Document details',
                  ),
                  if (!widget.document.isPdf)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _startSearch,
                      tooltip: 'Find in document',
                    ),
                ],
              ),
        body: Column(
          children: [
            Expanded(
              child: widget.document.isPdf
                  ? _buildPdfViewer()
                  : Markdown(
                controller: _scrollController,
                data: _getProcessedContent(),
                selectable: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: TextStyle(
                        fontSize: baseFontSize,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      h1: TextStyle(
                        fontSize: baseFontSize * 1.65,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      h2: TextStyle(
                        fontSize: baseFontSize * 1.35,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      h3: TextStyle(
                        fontSize: baseFontSize * 1.2,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      listBullet: TextStyle(
                        fontSize: baseFontSize,
                        color: primaryColor,
                      ),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: baseFontSize * 0.9,
                        backgroundColor: isDark
                            ? const Color(0xFF2A2E39)
                            : const Color(0xFFF1F3F5),
                        color: isDark
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF1F2937),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF21252D)
                            : const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: footerBorderColor),
                      ),
                      codeblockPadding: const EdgeInsets.all(16),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: primaryColor, width: 4),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(
                        left: 16,
                        top: 4,
                        bottom: 4,
                      ),
                      del: const TextStyle(
                        backgroundColor: Color(0xFFFFF176),
                        color: Colors.black,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.bold,
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
              ),
            ),

            if (_isSearching)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2E39)
                      : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: footerBorderColor),
                ),
                child: Text(
                  'Search within this file',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Reading Progress Bar / Footer (Wireframe 03 & 04)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: footerBgColor,
                border: Border(
                  top: BorderSide(color: footerBorderColor, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _readingProgress,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? const Color(0xFF2D323E)
                              : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${(_readingProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildPdfViewer() {
    final filePath = widget.document.filePath;
    final rawBytes = widget.document.rawBytes;

    final params = PdfViewerParams(
      onViewerReady: (doc, controller) {
        if (!mounted) return;
        setState(() {
          _totalPages = doc.pages.isNotEmpty ? doc.pages.length : 1;
          _currentPage = 1;
          _readingProgress = (_currentPage / _totalPages).clamp(0.0, 1.0);
        });
      },
      onPageChanged: (pageNumber) {
        if (!mounted) return;
        setState(() {
          _currentPage = pageNumber ?? 1;
          _readingProgress = (_currentPage / _totalPages).clamp(0.0, 1.0);
        });
      },
    );

    if (filePath != null) {
      return PdfViewer.file(
        filePath,
        controller: _pdfController,
        params: params,
      );
    } else if (rawBytes != null) {
      return PdfViewer.data(
        rawBytes,
        sourceName: widget.document.fileName,
        controller: _pdfController,
        params: params,
      );
    }
    return const Center(child: Text('Unable to display PDF document'));
  }
}
