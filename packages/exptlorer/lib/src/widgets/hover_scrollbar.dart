import 'package:fluent_ui/fluent_ui.dart';

/// Scrollbar with hover-aware thickness animation and thumb highlighting.
///
/// Thin when idle, thickens when mouse approaches the right edge.
class HoverScrollbar extends StatefulWidget {
  const HoverScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.thinThickness = 4,
    this.thickThickness = 8,
    this.radius = 4,
  });

  final ScrollController controller;
  final Widget child;
  final double thinThickness;
  final double thickThickness;
  final double radius;

  @override
  State<HoverScrollbar> createState() => HoverScrollbarState();
}

class HoverScrollbarState extends State<HoverScrollbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _thicknessAnim;
  bool _listHovered = false;
  bool _nearEdge = false;
  bool _overThumb = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _thicknessAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.fastOutSlowIn,
    );
    _animCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thickness =
        widget.thinThickness +
        (widget.thickThickness - widget.thinThickness) * _thicknessAnim.value;

    const double hoverMargin = 20;
    final isDark = FluentTheme.of(context).brightness == .dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          onEnter: (_) => setState(() => _listHovered = true),
          onExit: (_) {
            _listHovered = false;
            if (_nearEdge) {
              _nearEdge = false;
              _animCtrl.reverse();
            }
            setState(() {});
          },
          onHover: (event) {
            final x = event.localPosition.dx;
            final near = x >= width - widget.thickThickness - hoverMargin;
            if (near != _nearEdge) {
              _nearEdge = near;
              if (near) {
                _animCtrl.forward();
              } else {
                _animCtrl.reverse();
              }
            }
            _overThumb = x >= width - widget.thickThickness * 1.5;
          },
          child: ScrollConfiguration(
            behavior: _NoScrollbarBehavior(),
            child: RawScrollbar(
              controller: widget.controller,
              trackVisibility: _listHovered,
              trackColor: isDark ? Colors.grey[140] : Colors.grey[40],
              trackBorderColor: isDark ? Colors.grey[120] : Colors.grey[60],
              thumbVisibility: _listHovered,
              thumbColor: _overThumb
                  ? (isDark ? Colors.grey[100] : Colors.grey[80])
                  : (isDark ? Colors.grey[140] : Colors.grey[40]),
              thickness: thickness,
              radius: Radius.circular(widget.radius),
              fadeDuration: const Duration(milliseconds: 200),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Suppresses the default platform scrollbar.
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
