import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'zen_glass.dart';

class LiquidGlassPosition {
  final double left;
  final double width;
  const LiquidGlassPosition(this.left, this.width);
}

class LiquidGlassMath {
  static LiquidGlassPosition calculate({
    required double pageOffset,
    required double tabWidth,
  }) {
    final int leftTab = pageOffset.floor();
    final double t = pageOffset - leftTab;

    // Calculate stretched edges using asymmetric curves
    final double leftPos = (leftTab + Curves.easeIn.transform(t)) * tabWidth;
    final double rightPos =
        (leftTab + 1 + Curves.easeOut.transform(t)) * tabWidth;

    return LiquidGlassPosition(leftPos, rightPos - leftPos);
  }
}

/// Animated glass indicator for the PageView-based navbar.
///
/// Uses native [BackdropFilter] for the blur + sage-green tint.
/// Per Zen Glass Hierarchy: this is nav chrome → it gets glass.
class LiquidGlassIndicator extends StatelessWidget {
  final double pageOffset;
  final double tabWidth;
  final double height;

  const LiquidGlassIndicator({
    super.key,
    required this.pageOffset,
    required this.tabWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final pos = LiquidGlassMath.calculate(
      pageOffset: pageOffset,
      tabWidth: tabWidth,
    );

    return Positioned(
      left: pos.left,
      width: pos.width,
      height: height,
      child: ZenGlass(borderRadius: height / 2, child: const SizedBox.expand()),
    );
  }
}
