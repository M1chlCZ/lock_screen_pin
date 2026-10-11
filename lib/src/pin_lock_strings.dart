import 'package:flutter/foundation.dart';

/// Text strings the lock screen uses.
@immutable
class PinLockStrings {
  /// Creates a set of lock screen strings.
  const PinLockStrings({
    this.wrongPassTitle = 'Wrong passcode',
    this.wrongPassContent = 'The passcode you entered is incorrect.',
    this.wrongPassCancelButtonText = 'OK',
    this.clearButtonLabel = 'Clear',
    this.backspaceButtonLabel = 'Backspace',
  });

  /// Title that the wrong passcode dialog shows at the top.
  final String wrongPassTitle;

  /// Message that the wrong passcode dialog shows.
  final String wrongPassContent;

  /// Label of the button that dismisses the wrong passcode dialog.
  final String wrongPassCancelButtonText;

  /// Accessibility label of the keypad key that clears all entered digits.
  final String clearButtonLabel;

  /// Accessibility label of the keypad key that deletes the last digit.
  final String backspaceButtonLabel;
}
