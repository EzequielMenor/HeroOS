import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

double kWebBreakpoint = 900.0;

/// Flag to override [kIsWeb] check during testing.
bool debugOverrideIsWeb = false;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Desktop layout: running on a native desktop platform or on web at ≥900px wide.
  bool get isWeb =>
      (kIsWeb || _isDesktopPlatform || debugOverrideIsWeb) &&
      screenWidth >= kWebBreakpoint;

  /// Mobile/Tablet layout: running on mobile platforms or web/desktop <900px.
  bool get isMobileWeb =>
      !(kIsWeb || _isDesktopPlatform || debugOverrideIsWeb) ||
      screenWidth < kWebBreakpoint;
}
