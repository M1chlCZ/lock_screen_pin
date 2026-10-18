# lock_screen_pin

A customizable PIN lock screen for Flutter. It gives you a numeric keypad,
PIN dots, wrong-PIN feedback, and optional biometric hooks.

## Features

- Numeric keypad with clear and backspace keys
- PIN dots with accepted and rejected colors
- Wrong-PIN dialog with configurable text
- Biometric entry hooks: fingerprint area and automatic success
- Attempt lockout with `maxAttempts` and `lockoutDuration`
- PIN codec hook: keep only a hash with `PinCodec` and `expectedCode`
- Haptic feedback on accepted and rejected entries
- Accessibility labels on the keypad keys and the PIN dots
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

## Lockout

Set `maxAttempts` to limit the number of wrong entries. After the limit the
keypad disables for `lockoutDuration`, the dots reset, and `onLockoutStart`
fires once. The keypad enables again after the duration and `onLockoutEnd`
fires once. A correct entry resets the attempt counter.

```dart
LockScreen(
  title: 'Enter your PIN',
  passLength: 4,
  maxAttempts: 3,
  lockoutDuration: const Duration(seconds: 30),
  onLockoutStart: () => debugPrint('Keypad locked'),
  onLockoutEnd: () => debugPrint('Keypad unlocked'),
  passCodeVerify: (code) async => code.join() == '1234',
  onSuccess: () {},
);
```

`lockoutDuration` defaults to 30 seconds. When `maxAttempts` is null, the
lock screen never locks out. Read `remainingAttempts` and `isLockedOut` from
a `GlobalKey<LockScreenState>`:

```dart
final lockScreenKey = GlobalKey<LockScreenState>();

LockScreen(
  key: lockScreenKey,
  title: 'Enter your PIN',
  passLength: 4,
  maxAttempts: 3,
  passCodeVerify: (code) async => code.join() == '1234',
  onSuccess: () {},
);

final attemptsLeft = lockScreenKey.currentState?.remainingAttempts;
final locked = lockScreenKey.currentState?.isLockedOut ?? false;
```

## PIN codec

Store only a hash of the PIN code with `expectedCode` and `codec`. The
`IdentityPinCodec` default compares the stored value as plain text.

```dart
LockScreen(
  title: 'Enter your PIN',
  passLength: 4,
  expectedCode: storedHash,
  codec: const IdentityPinCodec(),
  onSuccess: () {},
);
```

Implement `PinCodec` to hash with a real algorithm:

```dart
class ReversedPinCodec implements PinCodec {
  const ReversedPinCodec();

  @override
  String hash(String pin) => pin.split('').reversed.join();

  @override
  bool verify(String pin, String expected) => hash(pin) == expected;
}
```

The widget calls `verify` with the entered digits and the stored value. When
both `passCodeVerify` and `expectedCode` are set, `passCodeVerify` wins. One
of the two is required.

## Haptics

`hapticsEnabled` defaults to `true`. The lock screen fires a light impact on
success and a heavy impact on a wrong entry. Biometric success fires no
haptics. Set `hapticsEnabled` to `false` to disable haptics.

## Accessibility

The keypad keys announce labels such as "Digit 5". The code panel announces
the entered digit count, for example "PIN entry, 3 of 6 digits entered". The
clear and backspace labels come from `PinLockStrings`.

## Configuration

- `passLength` accepts values from 1 to 8. Other values fail an assertion.
- Provide `passCodeVerify` or `expectedCode`. `passCodeVerify` wins when both
  are set.
- `maxAttempts` sets the wrong-entry limit; `lockoutDuration` defaults to 30
  seconds.
- `hapticsEnabled` defaults to `true`.
- `styles` on `LockScreen` takes precedence over a `PinLockTheme` in
  `ThemeData.extensions`.
- `PinLockStrings` sets the labels for the clear key, the backspace key, and
  the wrong-PIN dialog.

## Example

The [`example/`](example/) app shows a four-digit PIN lock screen.
