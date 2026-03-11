import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const double kWebBreakpoint = 900.0;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Desktop web: running in a browser at ≥900px wide.
  /// Fixed: now includes kIsWeb guard (previously missing — wide iPads triggered web layout).
  bool get isWeb => kIsWeb && screenWidth >= kWebBreakpoint;

  /// Mobile web: running in a browser at <900px (phone/tablet browser).
  bool get isMobileWeb => kIsWeb && screenWidth < kWebBreakpoint;

  /// Desktop web: explicit alias for clarity alongside isMobileWeb.
  bool get isDesktopWeb => kIsWeb && screenWidth >= kWebBreakpoint;
}
