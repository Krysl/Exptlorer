import 'package:flutter/material.dart';

class HoverVisible extends StatefulWidget {
  const HoverVisible({super.key, required this.child});

  final Widget child;

  @override
  State<HoverVisible> createState() => _HoverVisibleState();
}

class _HoverVisibleState extends State<HoverVisible> {
  bool visiable = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setState(() {
        visiable = true;
      }),
      onExit: (event) => setState(() {
        visiable = false;
      }),
      child: AnimatedOpacity(
        opacity: visiable ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: FittedBox(child: widget.child),
      ),
    );
  }
}
