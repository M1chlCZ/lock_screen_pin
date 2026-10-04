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
    bool showFingerPass = false,
    Widget? fingerPrintImage,
    PinLockTheme? styles,
    PinLockStrings strings = const PinLockStrings(),
  }) {
    tester.view.physicalSize = const Size(700, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          title: 'Enter passcode',
          passLength: passLength,
          passCodeVerify: verify,
          onSuccess: onSuccess ?? () {},
          fingerVerify: fingerVerify,
          fingerFunction: fingerFunction,
          showFingerPass: showFingerPass,
          fingerPrintImage: fingerPrintImage,
          styles: styles,
          strings: strings,
        ),
      ),
    );
  }

  Future<void> enterDigits(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
  }

  group('LockScreen', () {
    testWidgets('calls onSuccess when the correct passcode is entered', (
      tester,
    ) async {
      var success = false;
      await pumpLockScreen(
        tester,
        verify: (code) async => code.join() == '1234',
        onSuccess: () => success = true,
      );

      await enterDigits(tester, '1234');
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

      await enterDigits(tester, '9876');
      await tester.pump();

      expect(received, [9, 8, 7, 6]);
    });

    testWidgets('resets entered dots after a wrong passcode', (tester) async {
      final attempts = <List<int>>[];
      await pumpLockScreen(
        tester,
        verify: (code) async {
          attempts.add(code);
          return false;
        },
      );

      await enterDigits(tester, '1111');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await enterDigits(tester, '2345');
      await tester.pump();

      expect(attempts, [
        [1, 1, 1, 1],
        [2, 3, 4, 5],
      ]);
    });

    testWidgets('backspace decrements the code length before verification', (
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

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(received, isNull);

      await tester.tap(find.text('5'));
      await tester.pump();

      expect(received, [1, 3, 4, 5]);
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

    testWidgets('auto-invokes onSuccess when fingerVerify is true', (
      tester,
    ) async {
      var success = false;
      await pumpLockScreen(
        tester,
        verify: (code) async => false,
        onSuccess: () => success = true,
        fingerVerify: true,
        fingerFunction: () {},
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(success, isTrue);
    });

    testWidgets('tapping the fingerprint image invokes fingerFunction', (
      tester,
    ) async {
      var calls = 0;
      await pumpLockScreen(
        tester,
        verify: (code) async => false,
        showFingerPass: true,
        fingerPrintImage: const Icon(Icons.fingerprint),
        fingerFunction: () => calls++,
      );

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();

      expect(calls, 1);
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

    test('rejects a passLength of zero', () {
      expect(
        () => LockScreen(
          title: 't',
          passLength: 0,
          passCodeVerify: (code) async => false,
          onSuccess: () {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('verifies after a single digit when passLength is 1', (
      tester,
    ) async {
      List<int>? received;
      var success = false;
      await pumpLockScreen(
        tester,
        passLength: 1,
        verify: (code) async {
          received = code;
          return true;
        },
        onSuccess: () => success = true,
      );

      await tester.tap(find.text('7'));
      await tester.pump();

      expect(received, [7]);
      expect(success, isTrue);
    });

    testWidgets('schedules onSuccess when fingerVerify flips false to true', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var success = false;
      var fingerVerify = false;
      late StateSetter rebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return LockScreen(
                title: 'Enter passcode',
                passLength: 4,
                passCodeVerify: (code) async => false,
                onSuccess: () => success = true,
                fingerVerify: fingerVerify,
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(success, isFalse);

      fingerVerify = true;
      rebuild(() {});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(success, isFalse);

      await tester.pump(const Duration(milliseconds: 100));
      expect(success, isTrue);
    });

    testWidgets(
      'cancels a pending fingerprint success when fingerVerify flips to false',
      (tester) async {
        tester.view.physicalSize = const Size(700, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var success = false;
        var fingerVerify = true;
        late StateSetter rebuild;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return LockScreen(
                  title: 'Enter passcode',
                  passLength: 4,
                  passCodeVerify: (code) async => false,
                  onSuccess: () => success = true,
                  fingerVerify: fingerVerify,
                );
              },
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        fingerVerify = false;
        rebuild(() {});
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(success, isFalse);
      },
    );

    testWidgets('turns the dots red after a wrong passcode', (tester) async {
      await pumpLockScreen(tester, verify: (code) async => false);

      await enterDigits(tester, '1234');
      await tester.pump();

      final decorations = dotDecorations(tester);
      expect(decorations, hasLength(4));
      for (final decoration in decorations) {
        expect(decoration.color, Colors.red.shade500);
        expect(decoration.border!.top.color, Colors.red.shade500);
      }

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a verifier that throws follows the rejection path', (
      tester,
    ) async {
      final attempts = <List<int>>[];
      await pumpLockScreen(
        tester,
        verify: (code) async {
          attempts.add(code);
          throw StateError('verification failed');
        },
      );

      await enterDigits(tester, '1234');
      await tester.pump();

      expect(attempts, [
        [1, 2, 3, 4],
      ]);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await enterDigits(tester, '5678');
      await tester.pump();

      expect(attempts, [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('styles argument beats the PinLockTheme extension', (
      tester,
    ) async {
      const extensionTheme = PinLockTheme(
        numberColor: Colors.blue,
        keyColor: Colors.blue,
        keyShadows: <BoxShadow>[BoxShadow(color: Colors.blue)],
      );
      const directTheme = PinLockTheme(
        numberColor: Colors.red,
        keyColor: Colors.red,
        keyShadows: <BoxShadow>[BoxShadow(color: Colors.red)],
      );

      Widget build(PinLockTheme? styles) {
        return MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[extensionTheme],
          ),
          home: LockScreen(
            title: 'Enter passcode',
            passLength: 4,
            passCodeVerify: (code) async => false,
            onSuccess: () {},
            styles: styles,
          ),
        );
      }

      await tester.pumpWidget(build(null));
      expect(tester.widget<Text>(find.text('1')).style?.color, Colors.blue);
      expect(keyShadows(tester), extensionTheme.keyShadows);
      expect(keyColor(tester), Colors.blue);

      await tester.pumpWidget(build(directTheme));
      expect(tester.widget<Text>(find.text('1')).style?.color, Colors.red);
      expect(keyShadows(tester), directTheme.keyShadows);
      expect(keyColor(tester), Colors.red);
    });

    testWidgets('keypad keys expose accessibility labels', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpLockScreen(tester, verify: (code) async => false);

      expect(find.bySemanticsLabel('Backspace'), findsOneWidget);
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);
      expect(find.bySemanticsLabel('5'), findsOneWidget);

      semantics.dispose();
    });
  });

  group('CodePanel', () {
    Future<void> pumpCodePanel(
      WidgetTester tester, {
      required int codeLength,
      required int currentLength,
      bool fingerVerify = false,
      CodePanelStatus status = CodePanelStatus.idle,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodePanel(
              codeLength: codeLength,
              currentLength: currentLength,
              fingerVerify: fingerVerify,
              status: status,
            ),
          ),
        ),
      );
    }

    testWidgets('fills dots up to currentLength', (tester) async {
      await pumpCodePanel(tester, codeLength: 4, currentLength: 2);

      final decorations = dotDecorations(tester);
      expect(decorations, hasLength(4));
      expect(decorations[0].color, Colors.white);
      expect(decorations[0].border!.top.width, 1);
      expect(decorations[1].color, Colors.white);
      expect(decorations[2].color, Colors.transparent);
      expect(decorations[2].border!.top.width, 2);
      expect(decorations[3].color, Colors.transparent);
    });

    testWidgets('shows a green fill when the passcode is accepted', (
      tester,
    ) async {
      await pumpCodePanel(
        tester,
        codeLength: 3,
        currentLength: 3,
        status: CodePanelStatus.accepted,
      );

      for (final decoration in dotDecorations(tester)) {
        expect(decoration.color, Colors.green.shade500);
        expect(decoration.border!.top.color, Colors.green.shade500);
      }
    });

    testWidgets('shows red borders when the passcode is rejected', (
      tester,
    ) async {
      await pumpCodePanel(
        tester,
        codeLength: 3,
        currentLength: 0,
        status: CodePanelStatus.rejected,
      );

      for (final decoration in dotDecorations(tester)) {
        expect(decoration.color, Colors.transparent);
        expect(decoration.border!.top.color, Colors.red.shade500);
      }
    });

    testWidgets('shows green dots while fingerprint verification is active', (
      tester,
    ) async {
      await pumpCodePanel(
        tester,
        codeLength: 3,
        currentLength: 0,
        fingerVerify: true,
      );

      for (final decoration in dotDecorations(tester)) {
        expect(decoration.color, Colors.green.shade500);
      }
    });
  });

  group('PinLockTheme', () {
    test('equal configurations compare equal and hash equally', () {
      const a = PinLockTheme(
        numberColor: Colors.red,
        keyColor: Colors.green,
        backgroundColor: Colors.black,
        keyShadows: <BoxShadow>[BoxShadow(color: Colors.red)],
      );
      const b = PinLockTheme(
        numberColor: Colors.red,
        keyColor: Colors.green,
        backgroundColor: Colors.black,
        keyShadows: <BoxShadow>[BoxShadow(color: Colors.red)],
      );
      const c = PinLockTheme(
        numberColor: Colors.blue,
        keyColor: Colors.green,
        backgroundColor: Colors.black,
        keyShadows: <BoxShadow>[BoxShadow(color: Colors.red)],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('keyShadows defaults are const and shared', () {
      const a = PinLockTheme();
      const b = PinLockTheme();
      expect(identical(a.keyShadows, b.keyShadows), isTrue);
      expect(() => a.keyShadows.add(const BoxShadow()), throwsUnsupportedError);
    });

    test('user keyShadows are exposed as an unmodifiable copy', () {
      final source = <BoxShadow>[const BoxShadow(color: Colors.red)];
      final theme = PinLockTheme(keyShadows: source);
      final exposed = theme.keyShadows;

      expect(exposed, hasLength(1));
      expect(
        () => exposed.add(const BoxShadow(color: Colors.blue)),
        throwsUnsupportedError,
      );

      source.add(const BoxShadow(color: Colors.blue));
      expect(exposed, hasLength(1));
    });

    test('lerp interpolates values at the midpoint', () {
      const a = PinLockTheme(numberColor: Colors.black, keyColor: Colors.black);
      const b = PinLockTheme(numberColor: Colors.white, keyColor: Colors.white);

      final mid = a.lerp(b, 0.5);
      expect(mid.numberColor, Color.lerp(Colors.black, Colors.white, 0.5));
      expect(mid.keyColor, Color.lerp(Colors.black, Colors.white, 0.5));

      expect(a.lerp(null, 0.5), a);
    });

    test('copyWith keeps values for null arguments', () {
      const base = PinLockTheme(
        numberColor: Colors.red,
        keyColor: Colors.green,
        backgroundColor: Colors.black,
      );

      expect(base.copyWith(), equals(base));

      final changed = base.copyWith(numberColor: Colors.blue);
      expect(changed.numberColor, Colors.blue);
      expect(changed.keyColor, Colors.green);
      expect(changed.backgroundColor, Colors.black);
    });
  });
}

List<BoxDecoration> dotDecorations(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .where(
        (decoration) =>
            decoration.shape == BoxShape.circle && decoration.border != null,
      )
      .toList();
}

List<BoxShadow> keyShadows(WidgetTester tester) {
  return keyKeyDecoration(tester).boxShadow!;
}

Color keyColor(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).boxShadow != null,
          ),
          matching: find.byType(Material),
        )
        .first,
  );
  return material.color!;
}

BoxDecoration keyKeyDecoration(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((decoration) => decoration.boxShadow != null);
}
