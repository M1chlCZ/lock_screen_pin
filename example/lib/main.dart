import 'package:flutter/material.dart';
import 'package:lock_screen_pin/lock_screen_pin.dart';

void main() {
  runApp(const LockScreenPinExampleApp());
}

/// Example application for `lock_screen_pin`.
class LockScreenPinExampleApp extends StatelessWidget {
  /// Creates the example application.
  const LockScreenPinExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lock_screen_pin example',
      theme: ThemeData(brightness: Brightness.dark),
      home: const PinLockPage(),
    );
  }
}

/// A page that shows a four-digit PIN lock screen.
class PinLockPage extends StatelessWidget {
  /// Creates a PIN lock page.
  const PinLockPage({super.key});

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unlocked')));
      },
    );
  }
}
