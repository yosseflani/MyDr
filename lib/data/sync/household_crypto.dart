import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:mydr/data/backup/recovery_key.dart';

/// Why a household secret could not be used.
enum HouseholdCryptoError {
  /// Not addressed to this key, not made by the claimed member, or changed.
  notAuthentic,

  /// Not in a format this version understands.
  unsupported,
}

class HouseholdCryptoException implements Exception {
  const HouseholdCryptoException(this.error);

  final HouseholdCryptoError error;

  @override
  String toString() => 'HouseholdCryptoException(${error.name})';
}

/// A member's long-term identity: an X25519 key pair, created on the device.
/// Only the 32-byte [seed] is stored (in the OS secure storage); only the
/// public key ever leaves the device.
class IdentityKeyPair {
  IdentityKeyPair._(this._keyPair, List<int> publicKey)
    : publicKey = Uint8List.fromList(publicKey);

  final SimpleKeyPair _keyPair;
  final Uint8List publicKey;

  static Future<IdentityKeyPair> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw const HouseholdCryptoException(HouseholdCryptoError.unsupported);
    }
    final pair = await HouseholdCrypto._x25519.newKeyPairFromSeed(seed);
    final public = await pair.extractPublicKey();
    return IdentityKeyPair._(pair, public.bytes);
  }

  /// Never shows the key.
  @override
  String toString() => 'IdentityKeyPair(…)';
}

/// A one-time invitation secret, shown to the inviting parent and passed to
/// the other parent outside the app (in person or by phone). It proves to
/// each side the other's public key, so the server can never swap one in.
///
/// 128 random bits, written like a recovery key: 28 characters in groups of
/// four, with check characters that catch typing mistakes.
class InviteCode {
  InviteCode._(this._key);

  final RecoveryKey _key;

  static InviteCode generate([Random? random]) =>
      InviteCode._(RecoveryKey.generate(random));

  /// Throws a [FormatException] for anything but a valid code.
  static InviteCode parse(String text) => InviteCode._(RecoveryKey.parse(text));

  static InviteCode fromBytes(List<int> bytes) =>
      InviteCode._(RecoveryKey.fromBytes(bytes));

  List<int> get bytes => List.unmodifiable(_key.bytes);

  String format() => _key.format();

  @override
  bool operator ==(Object other) => other is InviteCode && other._key == _key;

  @override
  int get hashCode => _key.hashCode;

  /// Never shows the code.
  @override
  String toString() => 'InviteCode(…)';
}

/// The cryptography of household sharing. Pure Dart, like [BackupCipher]'s,
/// so the same code runs in tests and on every device.
///
/// * **Household key:** 32 random bytes per epoch. Every shared change and
///   photo is encrypted with it (through `BackupCipher.withSecret`) before
///   upload. Removing a member starts a new epoch with a new key.
/// * **Key wrapping:** a household key is sent to a member encrypted with
///   AES-256-GCM under a key derived (HKDF-SHA256) from two X25519 shared
///   secrets: an ephemeral one, and one between the wrapping member's and
///   the recipient's identity keys. So only the recipient can unwrap it, and
///   it is accepted only if it was wrapped by a member whose key the
///   recipient already verified.
/// * **Invitations:** both sides authenticate their public keys with
///   HMAC-SHA256 under keys derived from the invite code.
/// * **Attestations:** each member entry carries an HMAC under a key derived
///   from the household key, so only a member can vouch for another
///   member's public key and role.
abstract final class HouseholdCrypto {
  static const DartX25519 _x25519 = DartX25519();
  static final AesGcm _aes = DartAesGcm.with256bits();
  static final Hkdf _hkdf = DartHkdf(hmac: DartHmac.sha256(), outputLength: 32);
  static final Hmac _hmac = DartHmac.sha256();

  static const int keyLength = 32;
  static const int _wrapVersion = 1;
  static const int _nonceLength = 12;
  static const int _tagLength = 16;

  static Uint8List _randomBytes(int length, Random? random) {
    final source = random ?? Random.secure();
    return Uint8List.fromList([
      for (var i = 0; i < length; i++) source.nextInt(256),
    ]);
  }

  /// A new identity seed, to keep in secure storage.
  static Uint8List newIdentitySeed([Random? random]) =>
      _randomBytes(32, random);

  /// A new household key.
  static Uint8List newHouseholdKey([Random? random]) =>
      _randomBytes(keyLength, random);

  /// A random id for a household, an invitation object or a media object;
  /// reveals nothing.
  static String newId([Random? random]) => _randomBytes(
    16,
    random,
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Wraps [householdKey] for the member with [recipientPublicKey].
  /// [context] names the household, the epoch and both members, and is
  /// authenticated: a wrapped key cannot be moved to another place.
  static Future<Uint8List> wrapKey({
    required List<int> householdKey,
    required IdentityKeyPair wrapper,
    required List<int> recipientPublicKey,
    required String context,
    Random? random,
  }) async {
    final ephemeral = await IdentityKeyPair.fromSeed(_randomBytes(32, random));
    final key = await _wrapKey(
      first: await _shared(ephemeral, recipientPublicKey),
      second: await _shared(wrapper, recipientPublicKey),
      ephemeralPublic: ephemeral.publicKey,
      recipientPublic: recipientPublicKey,
      wrapperPublic: wrapper.publicKey,
      context: context,
    );
    final nonce = _randomBytes(_nonceLength, random);
    final box = await _aes.encrypt(
      householdKey,
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(context),
    );
    return Uint8List.fromList([
      _wrapVersion,
      ...ephemeral.publicKey,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Unwraps a key wrapped for [recipient] by the member with
  /// [wrapperPublicKey]. Throws a [HouseholdCryptoException] if anything
  /// does not match.
  static Future<Uint8List> unwrapKey({
    required List<int> wrapped,
    required IdentityKeyPair recipient,
    required List<int> wrapperPublicKey,
    required String context,
  }) async {
    const expected = 1 + 32 + _nonceLength + keyLength + _tagLength;
    if (wrapped.length != expected || wrapped[0] != _wrapVersion) {
      throw const HouseholdCryptoException(HouseholdCryptoError.unsupported);
    }
    final ephemeralPublic = wrapped.sublist(1, 33);
    final nonce = wrapped.sublist(33, 33 + _nonceLength);
    final cipherText = wrapped.sublist(
      33 + _nonceLength,
      33 + _nonceLength + keyLength,
    );
    final tag = wrapped.sublist(33 + _nonceLength + keyLength);
    try {
      final key = await _wrapKey(
        first: await _shared(recipient, ephemeralPublic),
        second: await _shared(recipient, wrapperPublicKey),
        ephemeralPublic: ephemeralPublic,
        recipientPublic: recipient.publicKey,
        wrapperPublic: wrapperPublicKey,
        context: context,
      );
      final plain = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
        secretKey: key,
        aad: utf8.encode(context),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const HouseholdCryptoException(HouseholdCryptoError.notAuthentic);
    }
  }

  /// HMAC-SHA256 under a key derived from [secret] for [purpose], over
  /// [parts] (each length-prefixed, so they can never run together).
  static Future<Uint8List> mac(
    List<int> secret,
    String purpose,
    List<Object> parts,
  ) async {
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(List.of(secret)),
      nonce: const [],
      info: utf8.encode('mydr-household-v1|$purpose'),
    );
    final message = BytesBuilder();
    for (final part in parts) {
      final bytes = part is String ? utf8.encode(part) : part as List<int>;
      message
        ..add([
          (bytes.length >> 24) & 0xff,
          (bytes.length >> 16) & 0xff,
          (bytes.length >> 8) & 0xff,
          bytes.length & 0xff,
        ])
        ..add(bytes);
    }
    final result = await _hmac.calculateMac(
      message.takeBytes(),
      secretKey: key,
    );
    return Uint8List.fromList(result.bytes);
  }

  /// Checks [expected] in constant time.
  static Future<bool> verifyMac(
    List<int> secret,
    String purpose,
    List<Object> parts,
    List<int> expected,
  ) async {
    final actual = await mac(secret, purpose, parts);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }

  /// The id under which an invitation is stored: derived from the code, so
  /// it can be looked up with the code and reveals nothing about it.
  static Future<String> inviteId(InviteCode code) async {
    final bytes = await mac(code.bytes, 'invite id', const []);
    return bytes
        .sublist(0, 16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// A short, readable fingerprint of a public key, for comparing in person:
  /// 16 characters of Crockford base32 from its SHA-256 (80 bits).
  static String fingerprint(List<int> publicKey) {
    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    final digest = hash.sha256.convert(publicKey).bytes.sublist(0, 10);
    var bits = BigInt.zero;
    for (final byte in digest) {
      bits = (bits << 8) | BigInt.from(byte);
    }
    final chars = List.filled(16, '');
    for (var i = 15; i >= 0; i--) {
      chars[i] = alphabet[(bits & BigInt.from(31)).toInt()];
      bits >>= 5;
    }
    final text = chars.join();
    return [for (var i = 0; i < 16; i += 4) text.substring(i, i + 4)].join(' ');
  }

  static Future<List<int>> _shared(
    IdentityKeyPair own,
    List<int> remotePublicKey,
  ) async {
    if (remotePublicKey.length != 32) {
      throw const HouseholdCryptoException(HouseholdCryptoError.unsupported);
    }
    final secret = await _x25519.sharedSecretKey(
      keyPair: own._keyPair,
      remotePublicKey: SimplePublicKey(
        List.of(remotePublicKey),
        type: KeyPairType.x25519,
      ),
    );
    final bytes = await secret.extractBytes();
    // A low-order public key gives an all-zero secret: refuse it.
    if (bytes.every((b) => b == 0)) {
      throw const HouseholdCryptoException(HouseholdCryptoError.notAuthentic);
    }
    return bytes;
  }

  static Future<SecretKey> _wrapKey({
    required List<int> first,
    required List<int> second,
    required List<int> ephemeralPublic,
    required List<int> recipientPublic,
    required List<int> wrapperPublic,
    required String context,
  }) => _hkdf.deriveKey(
    secretKey: SecretKey([...first, ...second]),
    nonce: [...ephemeralPublic, ...recipientPublic, ...wrapperPublic],
    info: utf8.encode('mydr-household-wrap-v1|$context'),
  );
}
