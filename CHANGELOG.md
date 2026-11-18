## [0.4.0] - 2026-11-18

- Require Flutter 3.47 and Dart 3.13.
- Use the `material_ui` package for Material widgets.

## [0.3.0] - 2026-11-10

- Add `dotSize`, `dotSpacing`, and `dotBorderWidth` to `PinLockTheme`; the
  passcode panel reads them from the theme. Filled dots keep a one-pixel
  thinner border.
- Shake the passcode dots after a wrong entry. `shakeEnabled`,
  `shakeDuration`, and `shakeOffset` control the animation, and the screen
  skips it when the platform asks for reduced motion.
- Add `onForgotPin` and `PinLockStrings.forgotPinLabel` for a PIN recovery
  action that stays available during a lockout.

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
