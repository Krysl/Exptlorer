import 'package:fluent_ui/fluent_ui.dart';

/// A [Text] that responds to hover state from the enclosing [HoverButton].
///
/// Reads [HoverButtonInherited] to show a background color on hover.
class HoverText extends StatelessWidget {
  const HoverText(
    this.data, {
    super.key,
    this.style,
  });

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final states = HoverButtonInherited.maybeOf(context)?.states ?? {};
    final theme = FluentTheme.of(context);
    final res = theme.resources;
    final isDark = theme.brightness == .dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: states.isHovered ? res.cardBackgroundFillColorTertiary : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          data,
          style: (style ?? theme.typography.body)?.copyWith(
            color: states.isHovered ? (isDark ? Colors.white : Colors.black) : Colors.grey[isDark ? 50 : 140],
          ),
        ),
      ),
    );
  }
}
