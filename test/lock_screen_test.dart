import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_screen_pin/lock_screen_pin.dart';

void main() {
  Future<void> pumpLockScreen(
    WidgetTester tester, {
    required PassCodeVerify verify,
    VoidCallback? onSuccess,
    int passLength = 4,
    bool fingerVerify = false,
    VoidCallback? fingerFunction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          title: 'Enter passcode',
          passLength: passLength,
          passCodeVerify: verify,
          onSuccess: onSuccess ?? () {},
          fingerVerify: fingerVerify,
          fingerFunction: fingerFunction,
        ),
      ),
    );
  }

  testWidgets('calls onSuccess when the correct passcode is entered', (
    tester,
  ) async {
    var success = false;
    await pumpLockScreen(
      tester,
      verify: (code) async => code.join() == '1234',
      onSuccess: () => success = true,
    );

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(success, isTrue);
  });

  testWidgets('calls passCodeVerify once with the full passcode', (
    tester,
  ) async {
    List<int>? received;
    await pumpLockScreen(
      tester,
      verify: (code) async {
        received = code;
        return false;
      },
    );

    for (final digit in ['9', '8', '7', '6']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();

    expect(received, [9, 8, 7, 6]);
  });

  testWidgets('resets entered dots after a wrong passcode', (tester) async {
    var attempts = 0;
    await pumpLockScreen(
      tester,
      verify: (code) async {
        attempts++;
        return false;
      },
    );

    for (final digit in ['1', '1', '1', '1']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();

    expect(attempts, 1);
  });

  testWidgets('backspace removes only the last entered digit', (tester) async {
    List<int>? received;
    await pumpLockScreen(
      tester,
      verify: (code) async {
        received = code;
        return false;
      },
    );

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();

    expect(received, [1, 3, 4]);
  });

  testWidgets('clear button resets all entered digits', (tester) async {
    List<int>? received;
    await pumpLockScreen(
      tester,
      verify: (code) async {
        received = code;
        return false;
      },
    );

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.byIcon(Icons.close));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('6'));
    await tester.tap(find.text('7'));
    await tester.tap(find.text('8'));
    await tester.pump();

    expect(received, [5, 6, 7, 8]);
  });

  testWidgets('auto-invokes fingerFunction when fingerVerify is true', (
    tester,
  ) async {
    var called = false;
    await pumpLockScreen(
      tester,
      verify: (code) async => false,
      fingerVerify: true,
      fingerFunction: () => called = true,
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(called, isTrue);
  });

  test('rejects a passcode longer than 8 digits', () {
    expect(
      () => LockScreen(
        title: 't',
        passLength: 9,
        passCodeVerify: (code) async => false,
        onSuccess: () {},
      ),
      throwsAssertionError,
    );
  });
}
