import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as pkg;

/// Thin wrapper that delegates to the package's [GlassCard] and adds onTap support.
///
/// Public API is kept compatible with the original DIY version so screen
/// callers don't need signature changes.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  // biome-ignore unused: retained for API compat; package controls blur via settings
  final double sigma;
  // biome-ignore unused: retained for API compat; package controls alpha via settings
  final double alpha;
  final double borderRadius;

  /// Premium variant matches the prototype's `.glass-premium` tier (blur 14).
  /// Standard (default) matches `.glass-standard` (blur 8). Per-card override
  /// is used so we can leave the global `GlassThemeSettings` in `main.dart`
  /// untouched.
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
    final card = pkg.GlassCard(
      padding: padding ?? const EdgeInsets.all(16),
      shape: pkg.LiquidRoundedSuperellipse(borderRadius: borderRadius),
      settings: pkg.LiquidGlassSettings(
        thickness: 40,
        blur: premium ? 14.0 : 8.0,
        refractiveIndex: 0.6,
        lightIntensity: 0.7,
        saturation: 1.2,
      ),
      quality: pkg.GlassQuality.premium,
      useOwnLayer: true,
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
