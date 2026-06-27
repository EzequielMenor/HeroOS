import 'dart:ui';
import 'package:flutter/material.dart';

class ZenGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const ZenGlass({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0, // Blur alto pero suave
    this.opacity = 0.03, // Blanco ultra sutil, NUNCA oscuro
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.08), // Borde Fresnel
              width: 0.5,
            ),
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}
