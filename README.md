# lock_screen_pin

A customizable PIN/passcode lock screen for Flutter. It provides a numeric
keypad, passcode dots, wrong-passcode feedback, optional biometrics hooks, and
themeable colors and strings.

## Features

- Numeric keypad with clear and backspace keys
- Passcode dots with accepted and rejected status colors
- Wrong-passcode handling with a configurable dialog
- Biometric entry hooks: fingerprint area and automatic success
- Theming through `PinLockTheme`, including registration as a `ThemeExtension`
- Configurable strings through `PinLockStrings`

## Install

`lock_screen_pin` is not published on pub.dev yet. Depend on it with a path:

```yaml
dependencies:
  lock_screen_pin:
    path: packages/lock_screen_pin
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:lock_screen_pin/lock_screen_pin.dart';

void main() => runApp(const MaterialApp(home: PinPage()));

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LockScreen(
      title: 'Enter your PIN',
      passLength: 4,
      styles: const PinLockTheme(
        numberColor: Colors.white70,
        dotBorderColor: Colors.white,
      ),
      strings: const PinLockStrings(
        wrongPassTitle: 'Oops!',
        wrongPassContent: 'The passcode you entered is incorrect.',
        wrongPassCancelButtonText: 'Cancel',
      ),
      showWrongPassDialog: true,
      passCodeVerify: (code) async => code.join() == '1234',
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unlocked')),
        );
      },
    );
  }
}
```

## Biometrics

Biometric verification is app-provided. The package never shows a biometric
prompt itself.

Keep `fingerVerify` set to `false` and run your own biometric prompt (for
example with `local_auth`). Set `fingerVerify: true` only after your prompt
returns success. The lock screen then calls `onSuccess` automatically, either
when `fingerVerify` changes from `false` to `true` or in `initState` when it is
already `true`.

To show a tappable fingerprint area, set `showFingerPass: true` and provide
`fingerPrintImage`. Tapping the area calls `fingerFunction`, which is typically
where you start your biometric prompt:

```dart
var fingerVerified = false;

LockScreen(
  // ...
  showFingerPass: true,
  fingerPrintImage: const Icon(Icons.fingerprint),
  fingerVerify: fingerVerified,
  fingerFunction: () async {
    if (await runYourBiometricPrompt()) {
      setState(() => fingerVerified = true);
    }
  },
);
```

> **Warning:** Setting `fingerVerify: true` unconditionally, or before your own
> prompt succeeds, bypasses the PIN and calls `onSuccess` immediately.

## Configuration notes

- `passLength` accepts values from 1 to 8. Values outside that range fail an
  assertion.
- `styles` passed to `LockScreen` takes precedence over a `PinLockTheme`
  registered through `ThemeData.extensions`.
- `PinLockStrings` exposes `clearButtonLabel` and `backspaceButtonLabel` in
  addition to the wrong-passcode dialog strings.

## Example

A runnable app that shows a four-digit PIN lock screen lives in
[`example/`](example/).

## Screenshot

A screenshot for the pub.dev listing is not included yet. Run the example app
to see the keypad and the passcode dots.
