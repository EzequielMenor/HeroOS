import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable typography helpers for the Bento grid (Apple Industrial layout).
///
/// These match the CSS prototype's typographic scale:
/// - kicker: 10px, w600, tracking 1.5, muted (text-transform: uppercase on the caller)
/// - metric: serif, large, w600, negative tracking
/// - muted body: 12px, secondary, slight tracking
///
/// All widgets are StatelessWidget with const-friendly constructors.

/// Uppercase kicker label at the top of a Bento card.
/// Caller is responsible for passing the text already uppercased.
class BentoKicker extends StatelessWidget {
  final String text;
  const BentoKicker(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );
}

/// Serif big-number metric (e.g. "66%", "358,60 €").
/// Default 20px; pass [size] for the balance-tier 30px variant.
class BentoMetric extends StatelessWidget {
  final String text;
  final double size;
  const BentoMetric(this.text, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: size,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
          letterSpacing: -0.5,
        ),
      );
}

/// Muted body subtitle inside a Bento card.
class BentoMuted extends StatelessWidget {
  final String text;
  const BentoMuted(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 0.15,
        ),
      );
}

/// Non-interactive chip for stat callouts inside a Bento card.
/// Mirrors the prototype's `.glass-chip` (white 6% bg, white 8% border, radius 10).
class StatChip extends StatelessWidget {
  final String label;
  const StatChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}