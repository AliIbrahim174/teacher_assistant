import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfPageSelector extends StatefulWidget {
  const PdfPageSelector({
    super.key,
    required this.pdfPath,
    required this.bookName,
  });

  final String pdfPath;
  final String bookName;

  @override
  State<PdfPageSelector> createState() =>
      _PdfPageSelectorState();
}

class _PdfPageSelectorState
    extends State<PdfPageSelector> {
  PdfDocument? _document;

  final Map<int, Uint8List> _thumbnails = {};

  final Set<int> _selectedPages = {};

  bool _loadingDocument = true;
  bool _loadingThumbnails = false;

  int _pagesCount = 0;
  int _renderedPages = 0;

  @override
  void initState() {
    super.initState();

    _openDocument();
  }

  Future<void> _openDocument() async {
    try {
      final document =
          await PdfDocument.openFile(
        widget.pdfPath,
      );

      if (!mounted) {
        await document.close();
        return;
      }

      setState(() {
        _document = document;
        _pagesCount = document.pagesCount;
        _loadingDocument = false;
        _loadingThumbnails = true;
      });

      await _renderThumbnails();
    } catch (e) {
      debugPrint(
        'PDF open error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loadingDocument = false;
      });

      _showMessage(
        'تعذر فتح الكتاب.',
      );
    }
  }

  Future<void> _renderThumbnails() async {
    final document = _document;

    if (document == null) return;

    /*
     * Render sequentially on purpose.
     *
     * Android's PdfRenderer should not have several
     * pages open simultaneously. Each page is closed
     * before the next one is opened.
     */

    for (int pageNumber = 1;
        pageNumber <= _pagesCount;
        pageNumber++) {
      if (!mounted) return;

      PdfPage? page;

      try {
        page = await document.getPage(
          pageNumber,
        );

        final sourceWidth =
            page.width.toDouble();

        final sourceHeight =
            page.height.toDouble();

        const thumbnailWidth = 220.0;

        final scale =
            thumbnailWidth / sourceWidth;

        final thumbnailHeight =
            sourceHeight * scale;

        final rendered =
            await page.render(
          width: thumbnailWidth,
          height: thumbnailHeight,
          format:
              PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );

        if (!mounted) {
          await page.close();
          return;
        }

        final bytes = rendered?.bytes;

        if (bytes != null) {
          setState(() {
            _thumbnails[pageNumber] =
                bytes;

            _renderedPages =
                pageNumber;
          });
        }
      } catch (e) {
        debugPrint(
          'Page $pageNumber render error: $e',
        );
      } finally {
        if (page != null &&
            !page.isClosed) {
          await page.close();
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _loadingThumbnails = false;
    });
  }

  void _togglePage(
    int pageNumber,
  ) {
    setState(() {
      if (_selectedPages.contains(
        pageNumber,
      )) {
        _selectedPages.remove(
          pageNumber,
        );
      } else {
        _selectedPages.add(
          pageNumber,
        );
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(
          List.generate(
            _pagesCount,
            (index) => index + 1,
          ),
        );
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPages.clear();
    });
  }

  void _confirmSelection() {
    if (_selectedPages.isEmpty) {
      _showMessage(
        'اختاري صفحة واحدة على الأقل.',
      );
      return;
    }

    final pages =
        _selectedPages.toList()..sort();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تم اختيار الصفحات',
          ),
          content: Text(
            'الصفحات: ${pages.join('، ')}',
            textDirection:
                TextDirection.rtl,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'حسنًا',
              ),
            ),
          ],
        );
      },
    );

    debugPrint(
      'Selected PDF pages: $pages',
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
              TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    final document = _document;

    if (document != null &&
        !document.isClosed) {
      document.close();
    }

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loadingDocument) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جارٍ فتح الكتاب...',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xfff5f6f8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookName,
              overflow:
                  TextOverflow.ellipsis,
            ),
            Text(
              '$_pagesCount صفحة',
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed:
                _pagesCount == 0
                    ? null
                    : _selectAll,
            icon: const Icon(
              Icons.select_all,
            ),
            label: const Text(
              'اختيار الكل',
            ),
          ),
          TextButton.icon(
            onPressed:
                _selectedPages.isEmpty
                    ? null
                    : _clearSelection,
            icon: const Icon(
              Icons.deselect,
            ),
            label: const Text(
              'إلغاء التحديد',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_loadingThumbnails)
            LinearProgressIndicator(
              value: _pagesCount == 0
                  ? null
                  : _renderedPages /
                      _pagesCount,
            ),

          if (_loadingThumbnails)
            Padding(
              padding:
                  const EdgeInsets.all(
                8,
              ),
              child: Text(
                'جارٍ تجهيز الصفحات '
                '$_renderedPages / $_pagesCount',
              ),
            ),

          Expanded(
            child: GridView.builder(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemCount: _pagesCount,
              itemBuilder:
                  (context, index) {
                final pageNumber =
                    index + 1;

                return _PageCard(
                  pageNumber:
                      pageNumber,
                  imageBytes:
                      _thumbnails[
                          pageNumber],
                  selected:
                      _selectedPages
                          .contains(
                    pageNumber,
                  ),
                  onTap: () {
                    _togglePage(
                      pageNumber,
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color:
                        Color(0x22000000),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _selectedPages
                            .isEmpty
                        ? 'لم يتم اختيار صفحات'
                        : 'تم اختيار '
                            '${_selectedPages.length} صفحة',
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  FilledButton.icon(
                    onPressed:
                        _selectedPages
                                .isEmpty
                            ? null
                            : _confirmSelection,
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
                    label: const Text(
                      'استخدام الصفحات',
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
}

class _PageCard
    extends StatelessWidget {
  const _PageCard({
    required this.pageNumber,
    required this.imageBytes,
    required this.selected,
    required this.onTap,
  });

  final int pageNumber;
  final Uint8List? imageBytes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      elevation: selected ? 7 : 2,
      borderRadius:
          BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding:
                  const EdgeInsets.all(
                6,
              ),
              child: imageBytes == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : Image.memory(
                      imageBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback:
                          true,
                    ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 150,
                ),
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                      : Colors.white,
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color: selected
                        ? Theme.of(
                            context,
                          )
                            .colorScheme
                            .primary
                        : Colors
                            .grey
                            .shade500,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check,
                        color:
                            Colors.white,
                      )
                    : null,
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 6,
                ),
                color:
                    const Color(
                  0xddffffff,
                ),
                child: Text(
                  'صفحة $pageNumber',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}