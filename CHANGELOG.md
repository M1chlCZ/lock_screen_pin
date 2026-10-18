## [0.2.0] - 2026-10-18

- Attempt lockout with `maxAttempts`, `lockoutDuration`, `onLockoutStart`,
  `onLockoutEnd`, `remainingAttempts`, and `isLockedOut`.
- PIN codec hook with `PinCodec`, `IdentityPinCodec`, and `expectedCode`.
  `passCodeVerify` is now optional.
- Haptic feedback on entry results with `hapticsEnabled`.
- Accessibility labels on the keypad keys and the code panel.

## 0.1.2

- Documentation and internal cleanup.

## 0.1.1

- Rewrite the README. The install section now uses
  `flutter pub add lock_screen_pin`.

## 0.1.0

- Initial release.
- Numeric keypad and passcode code dots.
- Wrong-passcode handling with configurable dialog strings.
- Biometric entry hooks.
- Theming via `PinLockTheme`, a `ThemeExtension`.
- Configurable strings via `PinLockStrings`.
