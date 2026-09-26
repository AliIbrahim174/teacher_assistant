import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../models/board_item.dart';
import '../painters/board_painter.dart';
import '../painters/grid_painter.dart';

class TeachingBoardPage extends StatefulWidget {
  const TeachingBoardPage({
    super.key,
    required this.pdfPath,
    required this.bookName,
    required this.pages,
  });

  final String pdfPath;

  final String bookName;

  final List<int> pages;

  @override
  State<TeachingBoardPage> createState() => _TeachingBoardPageState();
}

class _TeachingBoardPageState extends State<TeachingBoardPage> {
  static const double _gridSize = 20;

  PdfDocument? _document;

  final Map<int, Uint8List> _pageCache = {};

  final Map<int, double> _pageAspectRatios = {};

  final Map<int, List<BoardItem>> _itemsByPage = {};

  final Map<int, List<BoardItem>> _redoByPage = {};

  int _currentIndex = 0;

  Uint8List? _currentPageImage;

  double _currentAspectRatio = 1 / 1.414;

  bool _loadingPage = true;

  String? _errorMessage;

  int _renderRequestId = 0;

  BoardTool _tool = BoardTool.pen;

  Color _selectedColor = Colors.black;

  double _strokeWidth = 3;

  bool _penOnly = true;

  bool _showGrid = false;

  int? _activePointer;

  FreehandItem? _activeFreehand;

  Offset? _dragStart;

  Offset? _dragCurrent;

  int get _currentPageNumber => widget.pages[_currentIndex];

  List<BoardItem> get _currentItems =>
      _itemsByPage.putIfAbsent(_currentPageNumber, () => []);

  List<BoardItem> get _currentRedoItems =>
      _redoByPage.putIfAbsent(_currentPageNumber, () => []);

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
      debugPrint('Teaching board PDF error: $e');

      if (!mounted) return;

      setState(() {
        _loadingPage = false;

        _errorMessage = 'تعذر فتح الكتاب.';
      });
    }
  }

  Future<void> _renderCurrentPage() async {
    final pageNumber = _currentPageNumber;

    final cached = _pageCache[pageNumber];

    final cachedRatio = _pageAspectRatios[pageNumber];

    if (cached != null && cachedRatio != null) {
      setState(() {
        _currentPageImage = cached;

        _currentAspectRatio = cachedRatio;

        _loadingPage = false;

        _errorMessage = null;
      });

      return;
    }

    final document = _document;

    if (document == null) return;

    final requestId = ++_renderRequestId;

    setState(() {
      _loadingPage = true;

      _currentPageImage = null;

      _errorMessage = null;
    });

    PdfPage? page;

    try {
      page = await document.getPage(pageNumber);

      final sourceWidth = page.width.toDouble();

      final sourceHeight = page.height.toDouble();

      final aspectRatio = sourceWidth / sourceHeight;

      const targetWidth = 1600.0;

      final scale = targetWidth / sourceWidth;

      final targetHeight = sourceHeight * scale;

      final rendered = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );

      final bytes = rendered?.bytes;

      if (!mounted || requestId != _renderRequestId) {
        return;
      }

      if (bytes == null) {
        setState(() {
          _loadingPage = false;

          _errorMessage = 'تعذر عرض الصفحة.';
        });

        return;
      }

      _pageCache[pageNumber] = bytes;

      _pageAspectRatios[pageNumber] = aspectRatio;

      setState(() {
        _currentPageImage = bytes;

        _currentAspectRatio = aspectRatio;

        _loadingPage = false;
      });
    } catch (e) {
      debugPrint('Page $pageNumber render error: $e');

      if (!mounted || requestId != _renderRequestId) {
        return;
      }

      setState(() {
        _loadingPage = false;

        _errorMessage = 'تعذر عرض هذه الصفحة.';
      });
    } finally {
      if (page != null && !page.isClosed) {
        await page.close();
      }
    }
  }

  bool _isStylus(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  bool _canUsePointer(PointerEvent event) {
    if (_loadingPage) {
      return false;
    }

    if (_penOnly) {
      return _isStylus(event);
    }

    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus ||
        event.kind == PointerDeviceKind.mouse;
  }

  Offset _snapToGrid(Offset point) {
    return Offset(
      (point.dx / _gridSize).round() * _gridSize,
      (point.dy / _gridSize).round() * _gridSize,
    );
  }

  void _pointerDown(PointerDownEvent event) {
    if (!_canUsePointer(event)) {
      return;
    }

    if (_activePointer != null) {
      return;
    }

    _activePointer = event.pointer;

    switch (_tool) {
      case BoardTool.pen:
      case BoardTool.highlighter:
        _startFreehand(event.localPosition);

        break;

      case BoardTool.eraser:
        _eraseAt(event.localPosition);

        break;

      case BoardTool.line:
        setState(() {
          _dragStart = event.localPosition;

          _dragCurrent = event.localPosition;
        });

        break;

      case BoardTool.axis:
        setState(() {
          _dragStart = _snapToGrid(event.localPosition);

          _dragCurrent = _dragStart;
        });

        break;
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    switch (_tool) {
      case BoardTool.pen:
      case BoardTool.highlighter:
        _updateFreehand(event.localPosition);

        break;

      case BoardTool.eraser:
        _eraseAt(event.localPosition);

        break;

      case BoardTool.line:
        setState(() {
          _dragCurrent = event.localPosition;
        });

        break;

      case BoardTool.axis:
        setState(() {
          _dragCurrent = _snapToGrid(event.localPosition);
        });

        break;
    }
  }

  void _pointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    _finishCurrentTool();

    setState(() {
      _activePointer = null;
    });
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    _resetPointerState();
  }

  void _startFreehand(Offset position) {
    final isHighlighter = _tool == BoardTool.highlighter;

    final item = FreehandItem(
      points: [position],
      color: isHighlighter
          ? _selectedColor.withValues(alpha: 0.28)
          : _selectedColor,
      width: isHighlighter ? _strokeWidth * 5 : _strokeWidth,
    );

    setState(() {
      _currentRedoItems.clear();

      _currentItems.add(item);

      _activeFreehand = item;
    });
  }

  void _updateFreehand(Offset position) {
    final active = _activeFreehand;

    if (active == null) {
      return;
    }

    if (active.points.isNotEmpty &&
        (active.points.last - position).distance < 0.5) {
      return;
    }

    setState(() {
      active.points.add(position);
    });
  }

  void _eraseAt(Offset position) {
    final items = _currentItems;

    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].hitTest(position)) {
        setState(() {
          items.removeAt(i);

          _currentRedoItems.clear();
        });

        return;
      }
    }
  }

  void _finishCurrentTool() {
    switch (_tool) {
      case BoardTool.pen:
      case BoardTool.highlighter:
        setState(() {
          _activeFreehand = null;
        });

        break;

      case BoardTool.eraser:
        break;

      case BoardTool.line:
        final start = _dragStart;

        final end = _dragCurrent;

        if (start != null && end != null && (end - start).distance > 5) {
          setState(() {
            _currentItems.add(
              LineItem(
                start: start,
                end: end,
                color: _selectedColor,
                width: _strokeWidth,
              ),
            );

            _currentRedoItems.clear();
          });
        }

        setState(() {
          _dragStart = null;

          _dragCurrent = null;
        });

        break;

      case BoardTool.axis:
        final origin = _dragStart;

        final current = _dragCurrent;

        if (origin != null && current != null) {
          final dx = (current.dx - origin.dx).abs();

          final dy = (current.dy - origin.dy).abs();

          double extent = math.max(dx, dy);

          if (extent < 60) {
            extent = 100;
          }

          extent = (extent / _gridSize).round() * _gridSize;

          final axisWidth = _strokeWidth < 2 ? 2.0 : _strokeWidth;

          setState(() {
            _currentItems.add(
              AxisItem(
                origin: origin,
                extent: extent,
                color: _selectedColor,
                width: axisWidth,
              ),
            );

            _currentRedoItems.clear();
          });
        }

        setState(() {
          _dragStart = null;

          _dragCurrent = null;
        });

        break;
    }
  }

  void _resetPointerState() {
    setState(() {
      _activePointer = null;

      _activeFreehand = null;

      _dragStart = null;

      _dragCurrent = null;
    });
  }

  void _selectTool(BoardTool tool) {
    _resetPointerState();

    setState(() {
      _tool = tool;
    });
  }

  void _undo() {
    final items = _currentItems;

    if (items.isEmpty) {
      return;
    }

    setState(() {
      _currentRedoItems.add(items.removeLast());
    });
  }

  void _redo() {
    final redo = _currentRedoItems;

    if (redo.isEmpty) {
      return;
    }

    setState(() {
      _currentItems.add(redo.removeLast());
    });
  }

  Future<void> _clearCurrentPage() async {
    if (_currentItems.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('مسح الكتابة'),
          content: const Text('هل تريدين مسح كل الكتابة من هذه الصفحة؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('مسح'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _currentItems.clear();

      _currentRedoItems.clear();
    });
  }

  Future<void> _nextPage() async {
    if (_loadingPage || _currentIndex >= widget.pages.length - 1) {
      return;
    }

    _resetPointerState();

    setState(() {
      _currentIndex++;
    });

    await _renderCurrentPage();
  }

  Future<void> _previousPage() async {
    if (_loadingPage || _currentIndex <= 0) {
      return;
    }

    _resetPointerState();

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
      backgroundColor: const Color(0xffdfe2e6),
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(),

            Expanded(child: _buildBoardArea()),

            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardArea() {
    if (_loadingPage) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('جارٍ تجهيز الصفحة...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final pageImage = _currentPageImage;

    if (pageImage == null) {
      return const Center(child: Text('تعذر عرض الصفحة.'));
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: AspectRatio(
          aspectRatio: _currentAspectRatio,
          child: Material(
            elevation: 6,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: _pointerUp,
              onPointerCancel: _pointerCancel,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    pageImage,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),

                  if (_showGrid)
                    const IgnorePointer(
                      child: CustomPaint(
                        painter: GridPainter(gridSize: _gridSize),
                      ),
                    ),

                  IgnorePointer(
                    child: CustomPaint(
                      painter: BoardPainter(
                        items: _currentItems,
                        tool: _tool,
                        dragStart: _dragStart,
                        dragCurrent: _dragCurrent,
                        previewColor: _selectedColor,
                        previewWidth: _strokeWidth,
                        gridSize: _gridSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Material(
      elevation: 3,
      color: Colors.white,
      child: SizedBox(
        height: 78,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_forward),
              ),

              const SizedBox(width: 4),

              SizedBox(
                width: 150,
                child: Text(
                  widget.bookName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              _toolButton(BoardTool.pen, Icons.edit, 'قلم'),

              _toolButton(
                BoardTool.highlighter,
                Icons.border_color,
                'هايلايتر',
              ),

              _toolButton(BoardTool.eraser, Icons.auto_fix_normal, 'ممحاة'),

              _toolButton(BoardTool.line, Icons.horizontal_rule, 'خط'),

              _toolButton(BoardTool.axis, Icons.add, 'محاور'),

              const SizedBox(width: 12),

              _colorButton(Colors.black),

              _colorButton(Colors.blue),

              _colorButton(Colors.red),

              _colorButton(Colors.green),

              _colorButton(Colors.orange),

              const SizedBox(width: 10),

              const Icon(Icons.line_weight, size: 19),

              SizedBox(
                width: 110,
                child: Slider(
                  min: 1,
                  max: 10,
                  value: _strokeWidth,
                  onChanged: (value) {
                    setState(() {
                      _strokeWidth = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 6),

              FilterChip(
                selected: _showGrid,
                onSelected: (value) {
                  setState(() {
                    _showGrid = value;
                  });
                },
                avatar: const Icon(Icons.grid_on, size: 18),
                label: const Text('شبكة'),
              ),

              const SizedBox(width: 6),

              const Text('القلم فقط'),

              Switch.adaptive(
                value: _penOnly,
                onChanged: (value) {
                  _resetPointerState();

                  setState(() {
                    _penOnly = value;
                  });
                },
              ),

              _actionButton(
                icon: Icons.undo,
                label: 'تراجع',
                onPressed: _currentItems.isEmpty ? null : _undo,
              ),

              _actionButton(
                icon: Icons.redo,
                label: 'إعادة',
                onPressed: _currentRedoItems.isEmpty ? null : _redo,
              ),

              _actionButton(
                icon: Icons.delete_outline,
                label: 'مسح',
                onPressed: _currentItems.isEmpty ? null : _clearCurrentPage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(BoardTool tool, IconData icon, String label) {
    final selected = _tool == tool;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilledButton.tonalIcon(
        onPressed: () {
          _selectTool(tool);
        },
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _colorButton(Color color) {
    final selected = _selectedColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.amber : Colors.grey.shade400,
            width: selected ? 4 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Material(
      elevation: 5,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _currentIndex == 0 || _loadingPage
                    ? null
                    : _previousPage,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('السابق'),
              ),

              const Spacer(),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'صفحة '
                    '$_currentPageNumber',
                    style: const TextStyle(
                      fontSize: 17,
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
                onPressed:
                    _currentIndex == widget.pages.length - 1 || _loadingPage
                    ? null
                    : _nextPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('التالي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
