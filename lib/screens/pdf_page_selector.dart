import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'selected_pages_preview.dart';

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

  final Set<int> _selectedPages = {};

  final Map<int, Future<Uint8List?>>
      _thumbnailFutures = {};

  Future<void> _renderQueue =
      Future.value();

  bool _loadingDocument = true;

  String? _errorMessage;

  int _pagesCount = 0;

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
        _pagesCount =
            document.pagesCount;
        _loadingDocument = false;
      });
    } catch (e) {
      debugPrint(
        'PDF open error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loadingDocument = false;
        _errorMessage =
            'تعذر فتح الكتاب.';
      });
    }
  }

  Future<Uint8List?>
      _thumbnailFor(
    int pageNumber,
  ) {
    return _thumbnailFutures
        .putIfAbsent(
      pageNumber,
      () {
        final completer =
            Completer<Uint8List?>();

        _renderQueue =
            _renderQueue.then(
          (_) async {
            if (!mounted) {
              if (!completer.isCompleted) {
                completer.complete(null);
              }

              return;
            }

            final document =
                _document;

            if (document == null) {
              if (!completer.isCompleted) {
                completer.complete(null);
              }

              return;
            }

            PdfPage? page;

            try {
              page =
                  await document.getPage(
                pageNumber,
              );

              final sourceWidth =
                  page.width.toDouble();

              final sourceHeight =
                  page.height.toDouble();

              const width = 220.0;

              final scale =
                  width / sourceWidth;

              final height =
                  sourceHeight * scale;

              final rendered =
                  await page.render(
                width: width,
                height: height,
                format:
                    PdfPageImageFormat
                        .png,
                backgroundColor:
                    '#FFFFFF',
              );

              if (!completer
                  .isCompleted) {
                completer.complete(
                  rendered?.bytes,
                );
              }
            } catch (e) {
              debugPrint(
                'Thumbnail '
                '$pageNumber error: $e',
              );

              if (!completer
                  .isCompleted) {
                completer.complete(null);
              }
            } finally {
              if (page != null &&
                  !page.isClosed) {
                await page.close();
              }
            }
          },
        );

        return completer.future;
      },
    );
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

  Future<void>
      _confirmSelection() async {
    if (_selectedPages.isEmpty) {
      _showMessage(
        'اختاري صفحة واحدة على الأقل.',
      );

      return;
    }

    final pages =
        _selectedPages.toList()
          ..sort();

    debugPrint(
      'Selected PDF pages: $pages',
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SelectedPagesPreview(
          pdfPath: widget.pdfPath,
          bookName: widget.bookName,
          pages: pages,
        ),
      ),
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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 20,
            ),
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
                  thumbnail:
                      _thumbnailFor(
                    pageNumber,
                  ),
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
                            '${_selectedPages.length}'
                            ' صفحة',
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
    required this.thumbnail,
    required this.selected,
    required this.onTap,
  });

  final int pageNumber;

  final Future<Uint8List?> thumbnail;

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
              child:
                  FutureBuilder<
                      Uint8List?>(
                future: thumbnail,
                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState !=
                      ConnectionState.done) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final bytes =
                      snapshot.data;

                  if (bytes == null) {
                    return const Center(
                      child: Icon(
                        Icons
                            .broken_image_outlined,
                        size: 40,
                      ),
                    );
                  }

                  return Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  );
                },
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 150,
                ),
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: selected
                      ? Theme.of(
                          context,
                        )
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