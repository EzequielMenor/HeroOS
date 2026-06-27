import 'dart:ui';
import 'package:flutter/material.dart';

/// Ultra-diffuse gold aura that sits behind the content to give the liquid
/// glass something to refract. Mirrors the HTML prototype's `.aura` element.
///
/// Place as the bottom layer of a [Stack] — typically in the main Scaffold
/// body, behind the PageView or content column.
///
/// CSS equivalent:
/// ```css
/// .aura {
///   background: radial-gradient(circle at 30% 10%, rgba(212,175,55,0.07) 0%, transparent 50%);
///   filter: blur(80px);
/// }
/// ```
class ZenAuraBackground extends StatelessWidget {
  const ZenAuraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.4, -0.8),
                colors: [
                  Color(0x20D4AF37), // AppColors.gold at ~12.5% opacity
                  Colors.transparent,
                ],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
