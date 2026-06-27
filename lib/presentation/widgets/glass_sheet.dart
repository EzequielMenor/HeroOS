import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bottom sheet with native BackdropFilter glass effect.
///
/// Per Zen Glass Hierarchy: sheets ARE overlay chrome → they get glass.
class GlassSheet extends StatelessWidget {
  final Widget child;
  final bool isDismissible;
  final double sigma;
  final double topRadius;

  const GlassSheet({
    super.key,
    required this.child,
    this.isDismissible = true,
    this.sigma = 24,
    this.topRadius = 24,
  });

  /// Show this sheet as a modal bottom sheet with native glass.
  Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topRadius),
        topRight: Radius.circular(topRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(topRadius),
              topRight: Radius.circular(topRadius),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
