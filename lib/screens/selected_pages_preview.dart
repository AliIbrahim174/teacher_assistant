import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class SelectedPagesPreview extends StatefulWidget {
  const SelectedPagesPreview({
    super.key,
    required this.pdfPath,
    required this.bookName,
    required this.pages,
  });

  final String pdfPath;
  final String bookName;
  final List<int> pages;

  @override
  State<SelectedPagesPreview> createState() => _SelectedPagesPreviewState();
}

class _SelectedPagesPreviewState extends State<SelectedPagesPreview> {
  PdfDocument? _document;

  Uint8List? _pageImage;

  int _currentIndex = 0;

  bool _loading = true;

  String? _errorMessage;

  int _renderRequestId = 0;

  int get _currentPageNumber => widget.pages[_currentIndex];

  @override
  void initState() {
    super.initState();

    _openDocument();
  }

  Future<void> _openDocument() async {
    try {
      final document = await PdfDocument.openFile(widget.pdfPath);

      if (!mounted) {
        await document.close();
        return;
      }

      _document = document;

      await _renderCurrentPage();
    } catch (e) {
      debugPrint('Preview PDF open error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'تعذر فتح صفحات الكتاب.';
      });
    }
  }

  Future<void> _renderCurrentPage() async {
    final document = _document;

    if (document == null) return;

    final requestId = ++_renderRequestId;

    setState(() {
      _loading = true;
      _pageImage = null;
      _errorMessage = null;
    });

    PdfPage? page;

    try {
      page = await document.getPage(_currentPageNumber);

      final sourceWidth = page.width.toDouble();

      final sourceHeight = page.height.toDouble();

      const targetWidth = 1600.0;

      final scale = targetWidth / sourceWidth;

      final targetHeight = sourceHeight * scale;

      final rendered = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );

      if (!mounted || requestId != _renderRequestId) {
        return;
      }

      setState(() {
        _pageImage = rendered?.bytes;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Preview page render error: $e');

      if (!mounted || requestId != _renderRequestId) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'تعذر عرض هذه الصفحة.';
      });
    } finally {
      if (page != null && !page.isClosed) {
        await page.close();
      }
    }
  }

  Future<void> _nextPage() async {
    if (_currentIndex >= widget.pages.length - 1) {
      return;
    }

    setState(() {
      _currentIndex++;
    });

    await _renderCurrentPage();
  }

  Future<void> _previousPage() async {
    if (_currentIndex <= 0) {
      return;
    }

    setState(() {
      _currentIndex--;
    });

    await _renderCurrentPage();
  }

  @override
  void dispose() {
    _renderRequestId++;

    final document = _document;

    if (document != null && !document.isClosed) {
      document.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe9eaed),
      appBar: AppBar(
        title: Text(widget.bookName, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _buildPage())),

          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildPage() {
    if (_loading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('جارٍ تجهيز الصفحة...', style: TextStyle(fontSize: 18)),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
        ],
      );
    }

    final bytes = _pageImage;

    if (bytes == null) {
      return const Text('تعذر عرض الصفحة.');
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 5,
        color: Colors.white,
        child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: _currentIndex == 0 || _loading ? null : _previousPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('السابق'),
            ),

            const Spacer(),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'صفحة $_currentPageNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentIndex + 1}'
                  ' من '
                  '${widget.pages.length}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),

            const Spacer(),

            FilledButton.tonalIcon(
              onPressed: _currentIndex == widget.pages.length - 1 || _loading
                  ? null
                  : _nextPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('التالي'),
            ),
          ],
        ),
      ),
    );
  }
}
