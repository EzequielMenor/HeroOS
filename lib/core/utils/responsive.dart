import 'package:flutter/material.dart';

const double kWebBreakpoint = 900.0;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isWeb => screenWidth >= kWebBreakpoint;
}
