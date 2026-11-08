import 'package:flutter_test/flutter_test.dart';
import 'package:lock_screen_pin/lock_screen_pin.dart';

void main() {
  test('uses the dot defaults', () {
    const theme = PinLockTheme();
    expect(theme.dotSize, 25);
    expect(theme.dotSpacing, 15);
    expect(theme.dotBorderWidth, 1);
  });

  test('copyWith keeps the other dot values', () {
    const theme = PinLockTheme(dotSize: 18);
    final copy = theme.copyWith(dotSpacing: 8);
    expect(copy.dotSize, 18);
    expect(copy.dotSpacing, 8);
    expect(copy, isNot(theme));
  });

  test('lerp keeps explicit dot values at the end points', () {
    const start = PinLockTheme(dotSize: 20);
    const end = PinLockTheme(dotSize: 30);
    expect(start.lerp(end, 0).dotSize, 20);
    expect(start.lerp(end, 1).dotSize, 30);
    expect(start.lerp(end, 0.5).dotSize, 25);
  });
}
