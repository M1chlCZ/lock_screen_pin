/// Hashes and verifies PIN codes.
///
/// A codec lets the lock screen store only a hash of the PIN code. The [hash]
/// method turns a PIN code into its stored form. The [verify] method checks
/// an entered PIN code against a stored value.
abstract class PinCodec {
  /// Returns the stored form of [pin].
  String hash(String pin);

  /// Returns `true` when [pin] matches the stored [expected] value.
  bool verify(String pin, String expected);
}

/// A [PinCodec] that stores PIN codes as plain text.
///
/// This codec is the default. It suits prototypes and tests. A production
/// app uses a codec with a real hash function.
class IdentityPinCodec implements PinCodec {
  /// Creates an identity codec.
  const IdentityPinCodec();

  @override
  String hash(String pin) => pin;

  @override
  bool verify(String pin, String expected) => pin == expected;
}
