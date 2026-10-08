# lock_screen_pin

A customizable PIN lock screen for Flutter. It gives you a numeric keypad,
PIN dots, wrong-PIN feedback, and optional biometric hooks.

## Features

- Numeric keypad with clear and backspace keys
- PIN dots with accepted and rejected colors
- Wrong-PIN dialog with configurable text
- Biometric entry hooks: fingerprint area and automatic success
- Theming with `PinLockTheme`, also as a `ThemeExtension`
- Localizable labels with `PinLockStrings`

## Install

```bash
flutter pub add lock_screen_pin
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:lock_screen_pin/lock_screen_pin.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LockScreen(
      title: 'Enter your PIN',
      passLength: 4,
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

Set `showWrongPassDialog` to `true` to show the wrong-PIN dialog. Pass
`PinLockStrings` to `strings` to change its text.

## Biometrics

The app verifies biometric data. The package never shows a biometric prompt.

Keep `fingerVerify` at `false` and run your own prompt, for example with
`local_auth`. Set `fingerVerify` to `true` only after the prompt succeeds. The
lock screen then calls `onSuccess`. To show a tappable fingerprint area, set
`showFingerPass` to `true` and provide `fingerPrintImage`. A tap calls
`fingerFunction`, where you start your prompt.

> **Warning:** If you set `fingerVerify` to `true` before your prompt succeeds,
> the lock screen calls `onSuccess` immediately and skips the PIN.

## Configuration

- `passLength` accepts values from 1 to 8. Other values fail an assertion.
- `styles` on `LockScreen` takes precedence over a `PinLockTheme` in
  `ThemeData.extensions`.
- `PinLockStrings` sets the labels for the clear key, the backspace key, and
  the wrong-PIN dialog.

## Example

The [`example/`](example/) app shows a four-digit PIN lock screen.
