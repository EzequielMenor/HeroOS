import 'dart:ui';
import 'package:flutter/material.dart';

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
    final double rightPos = (leftTab + 1 + Curves.easeOut.transform(t)) * tabWidth;

    return LiquidGlassPosition(leftPos, rightPos - leftPos);
  }
}

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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}