import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Theme values used by the lock screen widget.
///
/// Register a [PinLockTheme] with [ThemeData.extensions] or pass one directly
/// to the lock screen. Every value is optional; a missing value falls back to
/// the default documented on the corresponding getter.
@immutable
class PinLockTheme extends ThemeExtension<PinLockTheme> with Diagnosticable {
  /// Creates a lock screen theme.
  const PinLockTheme({
    Color? numberColor,
    Color? dotBorderColor,
    Color? dotFillColor,
    Color? backgroundColor,
    Color? keyColor,
    List<BoxShadow>? keyShadows,
    TextStyle? titleStyle,
  }) : _numberColor = numberColor,
       _dotBorderColor = dotBorderColor,
       _dotFillColor = dotFillColor,
       _backgroundColor = backgroundColor,
       _keyColor = keyColor,
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
  final Color? _keyColor;
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
  /// Used for the scaffold body behind the keypad. When null the widget falls
  /// back to [ThemeData.canvasColor].
  Color? get backgroundColor => _backgroundColor;

  /// Background color of every keypad key.
  ///
  /// When null the widget falls back to [ThemeData.canvasColor].
  Color? get keyColor => _keyColor;

  /// Shadows painted behind every keypad key.
  ///
  /// Defaults to two soft shadows that give the keys a raised look. A list
  /// supplied by the caller is exposed as an unmodifiable copy.
  List<BoxShadow> get keyShadows => _keyShadows == null
      ? _defaultKeyShadows
      : List<BoxShadow>.unmodifiable(_keyShadows);

  /// Text style of the screen title.
  ///
  /// When null the widget derives a bold, white 16px style from
  /// [ThemeData.textTheme]'s `titleMedium`.
  TextStyle? get titleStyle => _titleStyle;

  /// Creates a copy of this theme with the given fields replaced.
  ///
  /// A `null` argument keeps the current value of that field; it does not
  /// clear it. To reset a field to its fallback, construct a new
  /// [PinLockTheme] without passing that field.
  @override
  PinLockTheme copyWith({
    Color? numberColor,
    Color? dotBorderColor,
    Color? dotFillColor,
    Color? backgroundColor,
    Color? keyColor,
    List<BoxShadow>? keyShadows,
    TextStyle? titleStyle,
  }) {
    return PinLockTheme(
      numberColor: numberColor ?? _numberColor,
      dotBorderColor: dotBorderColor ?? _dotBorderColor,
      dotFillColor: dotFillColor ?? _dotFillColor,
      backgroundColor: backgroundColor ?? _backgroundColor,
      keyColor: keyColor ?? _keyColor,
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
      keyColor: Color.lerp(_keyColor, other._keyColor, t),
      keyShadows: BoxShadow.lerpList(_keyShadows, other._keyShadows, t),
      titleStyle: TextStyle.lerp(_titleStyle, other._titleStyle, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('numberColor', _numberColor))
      ..add(ColorProperty('dotBorderColor', _dotBorderColor))
      ..add(ColorProperty('dotFillColor', _dotFillColor))
      ..add(ColorProperty('backgroundColor', _backgroundColor))
      ..add(ColorProperty('keyColor', _keyColor))
      ..add(
        DiagnosticsProperty<List<BoxShadow>>(
          'keyShadows',
          _keyShadows,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextStyle>(
          'titleStyle',
          _titleStyle,
          defaultValue: null,
        ),
      );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PinLockTheme &&
        other._numberColor == _numberColor &&
        other._dotBorderColor == _dotBorderColor &&
        other._dotFillColor == _dotFillColor &&
        other._backgroundColor == _backgroundColor &&
        other._keyColor == _keyColor &&
        listEquals(other._keyShadows, _keyShadows) &&
        other._titleStyle == _titleStyle;
  }

  @override
  int get hashCode => Object.hash(
    _numberColor,
    _dotBorderColor,
    _dotFillColor,
    _backgroundColor,
    _keyColor,
    _keyShadows == null ? null : Object.hashAll(_keyShadows),
    _titleStyle,
  );
}
