import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

double kWebBreakpoint = 900.0;

/// Flag to override [kIsWeb] check during testing.
bool debugOverrideIsWeb = false;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Desktop web: running in a browser at ≥900px wide.
  /// Fixed: now includes kIsWeb guard (previously missing — wide iPads triggered web layout).
  bool get isWeb => (kIsWeb || debugOverrideIsWeb) && screenWidth >= kWebBreakpoint;

  /// Mobile web: running in a browser at <900px (phone/tablet browser).
  bool get isMobileWeb => (kIsWeb || debugOverrideIsWeb) && screenWidth < kWebBreakpoint;
}
