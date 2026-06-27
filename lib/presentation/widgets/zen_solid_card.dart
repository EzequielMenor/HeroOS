import 'package:flutter/material.dart';

/// **ZenSolidCard** — For content cards that should NOT have glass.
///
/// Tasks, notes, finance cards, etc. use this instead of ZenGlass.
/// Elevated dark surface with clean border radius.
class ZenSolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const ZenSolidCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
