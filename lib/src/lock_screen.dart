import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pin_codec.dart';
import 'pin_lock_strings.dart';
import 'pin_lock_theme.dart';

/// Verifies an entered passcode and reports the result.
typedef PassCodeVerify = Future<bool> Function(List<int> passcode);

/// Verification status that [CodePanel] displays.
enum CodePanelStatus {
  /// The lock screen has not verified a passcode yet.
  idle,

  /// The lock screen accepted the last passcode.
  accepted,

  /// The lock screen rejected the last passcode.
  rejected,
}

/// A PIN/passcode lock screen with a numeric keypad and passcode dots.
///
/// The screen supports attempt lockout, a PIN codec hook, haptic feedback,
/// and accessibility labels.
class LockScreen extends StatefulWidget {
  /// Creates a lock screen.
  ///
  /// Provide [passCodeVerify] or [expectedCode]. Both paths verify the entered
  /// passcode; [passCodeVerify] wins when both are set.
  const LockScreen({
    super.key,
    required this.onSuccess,
    required this.title,
    required this.passLength,
    this.passCodeVerify,
    this.expectedCode,
    this.codec = const IdentityPinCodec(),
    this.maxAttempts,
    this.lockoutDuration,
    this.onLockoutStart,
    this.onLockoutEnd,
    this.hapticsEnabled = true,
    this.fingerFunction,
    this.fingerVerify = false,
    this.showFingerPass = false,
    this.fingerPrintImage,
    this.showWrongPassDialog = false,
    this.strings = const PinLockStrings(),
    this.styles,
  }) : assert(passLength > 0),
       assert(passLength <= 8),
       assert(maxAttempts == null || maxAttempts > 0),
       assert(lockoutDuration == null || lockoutDuration > Duration.zero),
       assert(passCodeVerify != null || expectedCode != null);

  /// The lock screen calls this callback when it accepts the passcode.
  final VoidCallback onSuccess;

  /// Title that the lock screen shows above the passcode dots.
  final String title;

  /// Number of digits in the passcode. Must be between 1 and 8.
  final int passLength;

  /// Verifies the entered passcode.
  ///
  /// When null the lock screen verifies the passcode with [codec] and
  /// [expectedCode]. This callback wins over [expectedCode] when both are set.
  final PassCodeVerify? passCodeVerify;

  /// Stored passcode that the lock screen compares against.
  ///
  /// The lock screen stores this value and checks the entered passcode with
  /// [codec]. The value can hold a hash of the real passcode. Provide
  /// [passCodeVerify] instead when the app keeps the passcode outside the
  /// widget.
  final String? expectedCode;

  /// Codec that checks the entered passcode against [expectedCode].
  ///
  /// Defaults to [IdentityPinCodec], which compares plain text.
  final PinCodec codec;

  /// Number of wrong entries that start a lockout.
  ///
  /// When null the lock screen never locks out. The value must be greater
  /// than zero. A correct entry resets the count of wrong entries.
  final int? maxAttempts;

  /// Time the keypad stays disabled after a lockout.
  ///
  /// Defaults to 30 seconds. The lock screen ignores this value when
  /// [maxAttempts] is null.
  final Duration? lockoutDuration;

  /// Callback that the lock screen calls once when a lockout starts.
  final VoidCallback? onLockoutStart;

  /// Callback that the lock screen calls once when a lockout ends.
  final VoidCallback? onLockoutEnd;

  /// Whether the lock screen fires haptic feedback on entry results.
  ///
  /// Defaults to `true`. The screen fires a light impact on success and a
  /// heavy impact on a wrong entry. Biometric success fires no haptics.
  final bool hapticsEnabled;

  /// The lock screen calls this function when the user taps the fingerprint
  /// area.
  final VoidCallback? fingerFunction;

  /// Whether fingerprint verification is active.
  final bool fingerVerify;

  /// Whether to show the fingerprint area.
  final bool showFingerPass;

  /// Image that the lock screen shows inside the fingerprint area.
  final Widget? fingerPrintImage;

  /// Whether to show a dialog after a wrong passcode.
  final bool showWrongPassDialog;

  /// Text strings the lock screen uses.
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
  var _currentState = CodePanelStatus.idle;
  var _failedAttempts = 0;
  var _isLockedOut = false;
  Timer? _resetTimer;
  Timer? _fingerTimer;
  Timer? _lockoutTimer;

  /// Number of wrong entries left before the keypad locks out.
  ///
  /// Returns `null` when [LockScreen.maxAttempts] is null. The getter returns
  /// zero while the keypad is locked out. A correct entry resets the count.
  int? get remainingAttempts {
    final maxAttempts = widget.maxAttempts;
    if (maxAttempts == null) {
      return null;
    }
    final remaining = maxAttempts - _failedAttempts;
    return remaining < 0 ? 0 : remaining;
  }

  /// Whether the keypad is locked out after too many wrong entries.
  bool get isLockedOut => _isLockedOut;

  @override
  void initState() {
    super.initState();
    if (widget.fingerVerify) {
      _scheduleFingerSuccess();
    }
  }

  @override
  void didUpdateWidget(LockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fingerVerify && !oldWidget.fingerVerify) {
      _scheduleFingerSuccess();
    } else if (!widget.fingerVerify && oldWidget.fingerVerify) {
      _fingerTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _fingerTimer?.cancel();
    _lockoutTimer?.cancel();
    _inputCodes.clear();
    super.dispose();
  }

  void _scheduleFingerSuccess() {
    _fingerTimer?.cancel();
    _fingerTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onSuccess();
      }
    });
  }

  PinLockTheme _resolveStyles(BuildContext context) {
    return widget.styles ??
        Theme.of(context).extension<PinLockTheme>() ??
        const PinLockTheme();
  }

  void _onCodeClick(int code) {
    if (_isLockedOut) {
      return;
    }
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

  Future<void> _verifyPassCode() async {
    final passcode = List<int>.of(_inputCodes);
    var isAccepted = false;
    try {
      final verify = widget.passCodeVerify;
      if (verify != null) {
        isAccepted = await verify(passcode);
      } else {
        isAccepted = widget.codec.verify(passcode.join(), widget.expectedCode!);
      }
    } catch (_) {
      isAccepted = false;
    }
    if (!mounted) {
      return;
    }
    if (isAccepted) {
      _fingerTimer?.cancel();
      _failedAttempts = 0;
      if (widget.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _currentState = CodePanelStatus.accepted;
        _inputCodes.clear();
      });
      widget.onSuccess();
    } else {
      _handleWrongPassCode();
    }
  }

  void _handleWrongPassCode() {
    if (widget.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    _failedAttempts++;
    final maxAttempts = widget.maxAttempts;
    if (maxAttempts != null && _failedAttempts >= maxAttempts) {
      _startLockout();
    } else {
      setState(() {
        _currentState = CodePanelStatus.rejected;
      });
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 1000), _resetCodes);
    }
    if (widget.showWrongPassDialog) {
      _showWrongPassDialog();
    }
  }

  void _startLockout() {
    _isLockedOut = true;
    _resetTimer?.cancel();
    _lockoutTimer?.cancel();
    setState(() {
      _currentState = CodePanelStatus.idle;
      _currentCodeLength = 0;
      _inputCodes.clear();
    });
    widget.onLockoutStart?.call();
    _lockoutTimer = Timer(
      widget.lockoutDuration ?? const Duration(seconds: 30),
      _endLockout,
    );
  }

  void _endLockout() {
    if (!mounted) {
      return;
    }
    _failedAttempts = 0;
    setState(() {
      _isLockedOut = false;
    });
    widget.onLockoutEnd?.call();
  }

  void _resetCodes() {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentState = CodePanelStatus.idle;
      _currentCodeLength = 0;
      _inputCodes.clear();
    });
  }

  void _deleteCode() {
    if (_isLockedOut) {
      return;
    }
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = CodePanelStatus.idle;
        _currentCodeLength--;
        _inputCodes.removeAt(_currentCodeLength);
      }
    });
  }

  void _deleteAllCodes() {
    if (_isLockedOut) {
      return;
    }
    setState(() {
      if (_currentCodeLength > 0) {
        _currentState = CodePanelStatus.idle;
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
    required String semanticsLabel,
  }) {
    return Align(
      child: Semantics(
        container: true,
        button: true,
        label: semanticsLabel,
        onTap: onTap,
        excludeSemantics: true,
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
                color: styles.keyColor ?? Theme.of(context).canvasColor,
                child: InkWell(
                  splashColor: Colors.white30,
                  onTap: onTap,
                  child: Center(child: child),
                ),
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
      semanticsLabel: 'Digit $number',
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
      semanticsLabel: widget.strings.clearButtonLabel,
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
      semanticsLabel: widget.strings.backspaceButtonLabel,
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
      body: Container(
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
                        const SizedBox(height: 100),
                        Text(widget.title, style: titleStyle),
                        SizedBox(
                          height:
                              Theme.of(context).platform == TargetPlatform.iOS
                              ? 20
                              : 30,
                        ),
                        CodePanel(
                          codeLength: widget.passLength,
                          currentLength: _currentCodeLength,
                          dotBorderColor: styles.dotBorderColor,
                          dotFillColor: styles.dotFillColor,
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
              flex: Theme.of(context).platform == TargetPlatform.iOS ? 10 : 8,
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overscroll) {
                  overscroll.disallowIndicator();
                  return true;
                },
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
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
          ],
        ),
      ),
    );
  }
}

/// A row of dots that shows how many passcode digits the user entered.
class CodePanel extends StatelessWidget {
  /// Creates a passcode dot panel.
  const CodePanel({
    super.key,
    required this.codeLength,
    required this.currentLength,
    this.dotBorderColor = Colors.white,
    this.dotFillColor = Colors.transparent,
    this.fingerVerify = false,
    this.status = CodePanelStatus.idle,
  }) : assert(codeLength > 0),
       assert(currentLength >= 0),
       assert(currentLength <= codeLength);

  /// Total number of dots to display.
  final int codeLength;

  /// Number of dots the panel fills.
  final int currentLength;

  /// Border color of the dots.
  final Color dotBorderColor;

  /// Fill color of an empty dot.
  final Color dotFillColor;

  /// Whether fingerprint verification is active.
  final bool fingerVerify;

  /// Current verification status.
  final CodePanelStatus status;

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
      if (status == CodePanelStatus.accepted) {
        color = Colors.green.shade500;
      }
      if (status == CodePanelStatus.rejected) {
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

    return Semantics(
      container: true,
      label: 'PIN entry, $currentLength of $codeLength digits entered',
      child: SizedBox.fromSize(
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
      ),
    );
  }
}

/// Clips a rectangle into the slanted shape of lock screen backgrounds.
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
