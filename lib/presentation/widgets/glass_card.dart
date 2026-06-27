import 'package:flutter/material.dart';
import 'zen_solid_card.dart';

/// Wrapper card for dashboard bento grid and content lists.
///
/// Per the Zen Glass Hierarchy: content cards do NOT use glass.
/// They use the elevated dark surface from [ZenSolidCard].
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double sigma;
  final double alpha;
  final double borderRadius;
  final bool premium;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.sigma = 8,
    this.alpha = 0.6,
    this.borderRadius = 22,
    this.premium = false,
  });

  @override
  Widget build(BuildContext context) {
    return ZenSolidCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: borderRadius,
      child: child,
    );
  }
}
