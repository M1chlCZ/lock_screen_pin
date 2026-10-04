import 'package:flutter/material.dart';

/// Theme values used by the lock screen widget.
///
/// Register a [PinLockTheme] with [ThemeData.extensions] or pass one directly
/// to the lock screen. Every value is optional; a missing value falls back to
/// the default documented on the corresponding getter.
@immutable
class PinLockTheme extends ThemeExtension<PinLockTheme> {
  /// Creates a lock screen theme.
  const PinLockTheme({
    Color? numberColor,
    Color? dotBorderColor,
    Color? dotFillColor,
    Color? backgroundColor,
    List<BoxShadow>? keyShadows,
    TextStyle? titleStyle,
  }) : _numberColor = numberColor,
       _dotBorderColor = dotBorderColor,
       _dotFillColor = dotFillColor,
       _backgroundColor = backgroundColor,
       _keyShadows = keyShadows,
       _titleStyle = titleStyle;

  static const List<BoxShadow> _defaultKeyShadows = <BoxShadow>[
    BoxShadow(
      offset: Offset(-1, -1),
      blurRadius: 4,
      color: Color.fromRGBO(134, 134, 134, 0.15),
    ),
    BoxShadow(
      offset: Offset(1, 1),
      blurRadius: 4,
      color: Color.fromRGBO(2, 2, 2, 0.85),
    ),
  ];

  final Color? _numberColor;
  final Color? _dotBorderColor;
  final Color? _dotFillColor;
  final Color? _backgroundColor;
  final List<BoxShadow>? _keyShadows;
  final TextStyle? _titleStyle;

  /// Color of the keypad numbers and icons.
  ///
  /// Defaults to [Colors.black].
  Color get numberColor => _numberColor ?? Colors.black;

  /// Border color of an empty passcode dot.
  ///
  /// Defaults to [Colors.white].
  Color get dotBorderColor => _dotBorderColor ?? Colors.white;

  /// Fill color of an empty passcode dot.
  ///
  /// Defaults to [Colors.transparent].
  Color get dotFillColor => _dotFillColor ?? Colors.transparent;

  /// Background color of the lock screen.
  ///
  /// When null the widget falls back to [ThemeData.canvasColor].
  Color? get backgroundColor => _backgroundColor;

  /// Shadows painted behind every keypad key.
  ///
  /// Defaults to two soft shadows that give the keys a raised look.
  List<BoxShadow> get keyShadows => _keyShadows ?? _defaultKeyShadows;

  /// Text style of the screen title.
  ///
  /// When null the widget derives a bold, white 16px style from
  /// [ThemeData.textTheme]'s `titleMedium`.
  TextStyle? get titleStyle => _titleStyle;

  @override
  PinLockTheme copyWith({
    Color? numberColor,
    Color? dotBorderColor,
    Color? dotFillColor,
    Color? backgroundColor,
    List<BoxShadow>? keyShadows,
    TextStyle? titleStyle,
  }) {
    return PinLockTheme(
      numberColor: numberColor ?? _numberColor,
      dotBorderColor: dotBorderColor ?? _dotBorderColor,
      dotFillColor: dotFillColor ?? _dotFillColor,
      backgroundColor: backgroundColor ?? _backgroundColor,
      keyShadows: keyShadows ?? _keyShadows,
      titleStyle: titleStyle ?? _titleStyle,
    );
  }

  @override
  PinLockTheme lerp(ThemeExtension<PinLockTheme>? other, double t) {
    if (other is! PinLockTheme) {
      return this;
    }
    return PinLockTheme(
      numberColor: Color.lerp(_numberColor, other._numberColor, t),
      dotBorderColor: Color.lerp(_dotBorderColor, other._dotBorderColor, t),
      dotFillColor: Color.lerp(_dotFillColor, other._dotFillColor, t),
      backgroundColor: Color.lerp(_backgroundColor, other._backgroundColor, t),
      keyShadows: BoxShadow.lerpList(_keyShadows, other._keyShadows, t),
      titleStyle: TextStyle.lerp(_titleStyle, other._titleStyle, t),
    );
  }
}
