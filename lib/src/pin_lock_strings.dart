import 'package:flutter/foundation.dart';

/// Text strings displayed by the lock screen package.
@immutable
class PinLockStrings {
  /// Creates a set of lock screen strings.
  const PinLockStrings({
    this.wrongPassTitle = 'Wrong passcode',
    this.wrongPassContent = 'The passcode you entered is incorrect.',
    this.wrongPassCancelButtonText = 'OK',
  });

  /// Title shown at the top of the wrong passcode dialog.
  final String wrongPassTitle;

  /// Message shown inside the wrong passcode dialog.
  final String wrongPassContent;

  /// Label of the button that dismisses the wrong passcode dialog.
  final String wrongPassCancelButtonText;
}
