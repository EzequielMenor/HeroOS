import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/presentation/widgets/liquid_glass_indicator.dart';

void main() {
  test('LiquidGlassMath stretching calculation', () {
    // At t = 0 (exact tab center)
    final pos0 = LiquidGlassMath.calculate(pageOffset: 0.0, tabWidth: 80.0);
    expect(pos0.left, 0.0);
    expect(pos0.width, 80.0);

    // At t = 0.5 (moving from tab 0 to 1, stretching should peak)
    final posHalf = LiquidGlassMath.calculate(pageOffset: 0.5, tabWidth: 80.0);
    // Left edge moves slower (easeIn(0.5) < 0.5)
    expect(posHalf.left, lessThan(40.0));
    // Right edge moves faster (easeOut(0.5) > 0.5)
    expect(posHalf.left + posHalf.width, greaterThan(120.0));
    expect(posHalf.width, greaterThan(80.0)); // Stretched

    // At t = 1.0 (settled on tab 1)
    final pos1 = LiquidGlassMath.calculate(pageOffset: 1.0, tabWidth: 80.0);
    expect(pos1.left, 80.0);
    expect(pos1.width, 80.0);
  });
}