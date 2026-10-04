import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'pin_lock_strings.dart';
import 'pin_lock_theme.dart';

/// Verifies an entered passcode and reports whether it is accepted.
typedef PassCodeVerify = Future<bool> Function(List<int> passcode);

/// Signature for a callback that deletes the last entered passcode digit.
typedef DeleteCode = void Function();

/// A PIN/passcode lock screen with a numeric keypad and passcode dots.
class LockScreen extends StatefulWidget {
  /// Creates a lock screen.
  const LockScreen({
    super.key,
    required this.onSuccess,
    required this.title,
    required this.passLength,
    required this.passCodeVerify,
    this.fingerFunction,
    this.fingerVerify = false,
    this.showFingerPass = false,
    this.fingerPrintImage,
    this.showWrongPassDialog = false,
    this.strings = const PinLockStrings(),
    this.styles,
  }) : assert(passLength <= 8);

  /// Called when the entered passcode is accepted.
  final VoidCallback onSuccess;

  /// Title displayed above the passcode dots.
  final String title;

  /// Number of digits in the passcode. Must not exceed 8.
  final int passLength;

  /// Verifies the entered passcode.
  final PassCodeVerify passCodeVerify;

  /// Called when the fingerprint entry is used.
  final VoidCallback? fingerFunction;

  /// Whether fingerprint verification is active.
  final bool fingerVerify;

  /// Whether to show the fingerprint area.
  final bool showFingerPass;

  /// Image shown inside the fingerprint area.
  final Widget? fingerPrintImage;

  /// Whether to show a dialog after a wrong passcode.
  final bool showWrongPassDialog;

  /// Text used by the lock screen.
  final PinLockStrings strings;

  /// Theme values for the lock screen.
  final PinLockTheme? styles;

  @override
  LockScreenState createState() => LockScreenState();
}

/// State for [LockScreen].
class LockScreenState extends State<LockScreen> {
  var _currentCodeLength = 0;
  final _inputCodes = <int>[];
  var _currentState = 0;
  Timer? _resetTimer;
  Timer? _fingerTimer;

  @override
  void initState() {
    super.initState();
    if (widget.fingerVerify) {
      _fingerTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          widget.onSuccess();
        }
      });
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _fingerTimer?.cancel();
    super.dispose();
  }

  PinLockTheme _resolveStyles(BuildContext context) {
    return widget.styles ??
        Theme.of(context).extension<PinLockTheme>() ??
        const PinLockTheme();
  }

  void _onCodeClick(int code) {
    if (_currentCodeLength < widget.passLength) {
      setState(() {
        _currentCodeLength++;
        _inputCodes.add(code);
      });
      if (_currentCodeLength == widget.passLength) {
        _verifyPassCode();
      }
    }
  }

  void _verifyPassCode() {
    widget.passCodeVerify(List<int>.of(_inputCodes)).then((isAccepted) {
      if (!mounted) {
        return;
      }
      if (isAccepted) {
        setState(() {
          _currentState = 1;
        });
        widget.onSuccess();
      } else {
        _handleWrongPassCode();
      }
    });
  }

  void _handleWrongPassCode() {
    setState(() {
      _currentState = 2;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1000), _resetCodes);
    if (widget.showWrongPassDialog) {
      _showWrongPassDialog();
    }
  }

  void _resetCodes() {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentState = 0;
      _currentCodeLength = 0;
      _inputCodes.clear();
    });
  }

  void _deleteCode() {
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = 0;
        _currentCodeLength--;
        _inputCodes.removeAt(_currentCodeLength);
      }
    });
  }

  void _deleteAllCodes() {
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = 0;
        _currentCodeLength = 0;
        _inputCodes.clear();
      }
    });
  }

  void _showWrongPassDialog() {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(context).textTheme;
        return Center(
          child: AlertDialog(
            title: Text(
              widget.strings.wrongPassTitle,
              style: textTheme.titleMedium,
            ),
            content: Text(
              widget.strings.wrongPassContent,
              style: textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  widget.strings.wrongPassCancelButtonText,
                  style: textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey({
    required PinLockTheme styles,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Align(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: styles.keyShadows,
        ),
        child: ClipOval(
          child: SizedBox(
            height: 75,
            width: 75,
            child: Material(
              color: Theme.of(context).canvasColor,
              child: InkWell(
                splashColor: Colors.white30,
                onTap: onTap,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberKey(int number, PinLockTheme styles) {
    final textTheme = Theme.of(context).textTheme;
    return _buildKey(
      styles: styles,
      onTap: () => _onCodeClick(number),
      child: Text(
        number.toString(),
        style: (textTheme.headlineMedium ?? const TextStyle()).copyWith(
          color: styles.numberColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildClearKey(PinLockTheme styles) {
    return _buildKey(
      styles: styles,
      onTap: () {
        if (_currentCodeLength > 0) {
          _deleteAllCodes();
        }
      },
      child: Icon(Icons.close, size: 30, color: styles.numberColor),
    );
  }

  Widget _buildBackspaceKey(PinLockTheme styles) {
    return _buildKey(
      styles: styles,
      onTap: () {
        if (_currentCodeLength > 0) {
          _deleteCode();
        }
      },
      child: Icon(Icons.arrow_back, size: 30, color: styles.numberColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = _resolveStyles(context);
    final backgroundColor =
        styles.backgroundColor ?? Theme.of(context).canvasColor;
    final baseTitleStyle = Theme.of(context).textTheme.titleMedium;
    final titleStyle =
        styles.titleStyle ??
        (baseTitleStyle ?? const TextStyle()).copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Container(
            color: backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(color: backgroundColor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: Platform.isIOS ? 100 : 100),
                            Text(widget.title, style: titleStyle),
                            SizedBox(height: Platform.isIOS ? 20 : 30),
                            CodePanel(
                              codeLength: widget.passLength,
                              currentLength: _inputCodes.length,
                              dotBorderColor: styles.dotBorderColor,
                              dotFillColor: styles.dotFillColor,
                              deleteCode: _deleteCode,
                              fingerVerify: widget.fingerVerify,
                              status: _currentState,
                            ),
                          ],
                        ),
                      ),
                      if (widget.showFingerPass)
                        Positioned(
                          top: 10,
                          right: 15,
                          child: GestureDetector(
                            onTap: () => widget.fingerFunction?.call(),
                            child: SizedBox(
                              width: 60,
                              child: widget.fingerPrintImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: Platform.isIOS ? 10 : 8,
                  child: Container(
                    padding: const EdgeInsets.only(left: 0, top: 0),
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            mainAxisSpacing: 0,
                            padding: const EdgeInsets.all(20),
                            children: <Widget>[
                              _buildNumberKey(1, styles),
                              _buildNumberKey(2, styles),
                              _buildNumberKey(3, styles),
                              _buildNumberKey(4, styles),
                              _buildNumberKey(5, styles),
                              _buildNumberKey(6, styles),
                              _buildNumberKey(7, styles),
                              _buildNumberKey(8, styles),
                              _buildNumberKey(9, styles),
                              _buildClearKey(styles),
                              _buildNumberKey(0, styles),
                              _buildBackspaceKey(styles),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of dots that visualizes how many passcode digits were entered.
class CodePanel extends StatelessWidget {
  /// Creates a passcode dot panel.
  const CodePanel({
    super.key,
    required this.codeLength,
    required this.currentLength,
    this.dotBorderColor = Colors.white,
    this.dotFillColor = Colors.transparent,
    this.deleteCode,
    this.fingerVerify = false,
    this.status = 0,
  }) : assert(codeLength > 0),
       assert(currentLength >= 0),
       assert(currentLength <= codeLength),
       assert(status == 0 || status == 1 || status == 2);

  /// Total number of dots to display.
  final int codeLength;

  /// Number of dots that should appear filled.
  final int currentLength;

  /// Border color of the dots.
  final Color dotBorderColor;

  /// Fill color of an empty dot.
  final Color dotFillColor;

  /// Callback invoked when the panel is asked to delete a digit.
  final DeleteCode? deleteCode;

  /// Whether fingerprint verification is active.
  final bool fingerVerify;

  /// Current verification status: 0 idle, 1 accepted, 2 rejected.
  final int status;

  Widget _buildDot({
    required double size,
    required Color borderColor,
    required Color fillColor,
    required double borderWidth,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          color: fillColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dotSize = 25.0;
    final circles = <Widget>[];
    var color = dotBorderColor;

    if (fingerVerify) {
      for (var i = 0; i < codeLength; i++) {
        circles.add(
          _buildDot(
            size: dotSize,
            borderColor: color,
            fillColor: Colors.green.shade500,
            borderWidth: 1,
          ),
        );
      }
    } else {
      if (status == 1) {
        color = Colors.green.shade500;
      }
      if (status == 2) {
        color = Colors.red.shade500;
      }
      for (var i = 1; i <= codeLength; i++) {
        if (i > currentLength) {
          circles.add(
            _buildDot(
              size: dotSize,
              borderColor: color,
              fillColor: dotFillColor,
              borderWidth: 2,
            ),
          );
        } else {
          circles.add(
            _buildDot(
              size: dotSize,
              borderColor: color,
              fillColor: color,
              borderWidth: 1,
            ),
          );
        }
      }
    }

    return SizedBox.fromSize(
      size: Size(MediaQuery.of(context).size.width, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox.fromSize(
            size: Size(40.0 * codeLength, dotSize),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: circles,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips a rectangle into the slanted shape used by lock screen backgrounds.
class BgClipper extends CustomClipper<Path> {
  /// Creates a background clipper.
  const BgClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height / 1.5);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
