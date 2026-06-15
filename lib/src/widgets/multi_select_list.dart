import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:exptlorer/src/utils/num.dart';

import 'hover_scrollbar.dart';

/// A list widget that supports multi-selection via Ctrl/Shift click.
///
/// Replaces the old [MultiSelect] mixin + [multiSelectBuilder] pattern
/// with a standalone [StatefulWidget].
class MultiSelectList extends StatefulWidget {
  const MultiSelectList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.path,
    required this.isDir,
    this.onTapWithoutModifierKeys,
    this.showRightGuide = false,
    this.strokeWidth = 3,
    this.cornerRadius = 6,
  });

  final int itemCount;
  final Widget Function(int index, bool isSelected, bool isHovered) itemBuilder;
  final String Function(int index) path;
  final bool Function(int index) isDir;
  final void Function(String? path)? onTapWithoutModifierKeys;
  final double strokeWidth;
  final double cornerRadius;

  /// Whether to draw a vertical guide line on the right side,
  /// with a gap at the selected item's position.
  final bool showRightGuide;

  @override
  State<MultiSelectList> createState() => _MultiSelectListState();
}

class _MultiSelectListState extends State<MultiSelectList> {
  List<bool> _selected = [];
  int _lastSelected = 0;
  int? _hoveredIndex;
  final List<GlobalKey> _itemKeys = [];
  final _paintKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.itemCount, false);
    _syncKeys();
    _scrollController.addListener(() => _repaintNotifier.value++);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MultiSelectList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLength();
  }

  void _syncKeys() {
    if (_itemKeys.length != widget.itemCount) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(widget.itemCount, (_) => GlobalKey()));
    }
  }

  void _syncLength() {
    if (_selected.length != widget.itemCount) {
      _selected = List.filled(widget.itemCount, false);
      _syncKeys();
      _lastSelected = 0;
    }
  }

  void _select(int index) {
    final instance = HardwareKeyboard.instance;
    if (instance.isControlPressed) {
      _selected[index] = !_selected[index];
      _lastSelected = index;
    } else if (instance.isShiftPressed) {
      _selected.fillRange(0, _selected.length, false);
      final (start, end) = sort2(_lastSelected, index);
      _selected.fillRange(start, end + 1, true);
    } else {
      _selected.fillRange(0, _selected.length, false);
      _selected[index] = true;
      _lastSelected = index;
      widget.onTapWithoutModifierKeys?.call(
        widget.isDir(index) ? widget.path(index) : null,
      );
    }
    setState(() => _repaintNotifier.value++);
  }

  @override
  Widget build(BuildContext context) {
    _syncLength();
    final list = HoverScrollbar(
      controller: _scrollController,
      onTap: () => widget.onTapWithoutModifierKeys?.call(null),
      thinThickness: widget.strokeWidth,
      thickThickness: widget.strokeWidth * 2.5,
      radius: widget.cornerRadius,
      child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.itemCount,
          itemBuilder: (ctx, index) {
            final isSel = _selected[index];
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTapDown: (details) => _select(index),
                child: Padding(
                  key: _itemKeys[index],
                  padding: EdgeInsets.only(
                    left: widget.strokeWidth,
                    top: widget.strokeWidth / 2,
                    bottom: widget.strokeWidth / 2,
                  ),
                  child: widget.itemBuilder(
                      index, isSel, _hoveredIndex == index),
                ),
              ),
            );
          },
        ),
      );
    if (!widget.showRightGuide) return list;
    final theme = FluentTheme.of(context);
    return CustomPaint(
      key: _paintKey,
      foregroundPainter: _GuideOverlayPainter(
        repaint: _repaintNotifier,
        paintKey: _paintKey,
        gapItemKey: _itemKeys[_lastSelected],
        color: theme.accentColor,
        strokeWidth: widget.strokeWidth,
        cornerRadius: widget.cornerRadius,
      ),
      child: list,
    );
  }
}


/// Draws the right guide line and selected border at the top level.
class _GuideOverlayPainter extends CustomPainter {
  _GuideOverlayPainter({
    required this.repaint,
    required this.paintKey,
    required this.gapItemKey,
    required this.color,
    this.strokeWidth = 3,
    this.cornerRadius = 6,
  }) : super(repaint: repaint);

  final ValueNotifier<int> repaint;
  final GlobalKey paintKey;
  final GlobalKey gapItemKey;
  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paintBox = paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (paintBox == null) return;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..color = color;

    final rightX = size.width - strokeWidth / 2;

    // Get bounding box of the source item (has the next column).
    Rect? sourceRect;
    final ctx = gapItemKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        sourceRect =
            box.localToGlobal(Offset.zero, ancestor: paintBox) & box.size;
      }
    }

    // Draw the right guide line with a gap at the source item
    if (sourceRect == null) {
      canvas.drawLine(Offset(rightX, 0), Offset(rightX, size.height), paint);
    } else {
      if (sourceRect.top > 0) {
        canvas.drawLine(
          Offset(rightX, 0),
          Offset(rightX, sourceRect.top - cornerRadius+1),
          paint,
        );
      }
      if (sourceRect.bottom < size.height) {
        canvas.drawLine(
          Offset(rightX, sourceRect.bottom + cornerRadius-1),
          Offset(rightX, size.height),
          paint,
        );
      }
    }

    // Draw the selected border around the source item
    if (sourceRect != null) {
      _drawBorder(canvas, sourceRect, paint);
    }
  }

  void _drawBorder(Canvas canvas, Rect rect, Paint paint) {
    final r = cornerRadius;
    final w = rect.width;
    final h = rect.height;
    final lw = w - strokeWidth - 2 * r;
    final lh = h - 2 * r;
    final leftDown = Offset(-r, r);
    final rightDown = Offset(r, r);
    final rr = Radius.circular(r);

    final path = Path()
      ..moveTo(rect.right - strokeWidth / 2, rect.top - r)
      ..relativeArcToPoint(leftDown, radius: rr)
      ..relativeLineTo(-lw, 0)
      ..relativeArcToPoint(leftDown, radius: rr, clockwise: false)
      ..relativeLineTo(0, lh)
      ..relativeArcToPoint(rightDown, radius: rr, clockwise: false)
      ..relativeLineTo(lw, 0)
      ..relativeArcToPoint(rightDown, radius: rr);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GuideOverlayPainter oldDelegate) => true;
}
