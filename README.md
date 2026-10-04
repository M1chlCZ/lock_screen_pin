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

Biometric verification is app-provided. Set `fingerVerify: true` to make the
lock screen call `onSuccess` automatically once verification succeeds, and use
`fingerFunction` to run your own biometric prompt when the fingerprint area is
tapped.
