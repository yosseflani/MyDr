import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/backup/backup_cipher.dart';
import 'package:mydr/data/sync/household_crypto.dart';

void main() {
  final random = Random(42);
  late IdentityKeyPair alice;
  late IdentityKeyPair bob;
  late IdentityKeyPair mallory;

  setUp(() async {
    alice = await IdentityKeyPair.fromSeed(
      HouseholdCrypto.newIdentitySeed(random),
    );
    bob = await IdentityKeyPair.fromSeed(
      HouseholdCrypto.newIdentitySeed(random),
    );
    mallory = await IdentityKeyPair.fromSeed(
      HouseholdCrypto.newIdentitySeed(random),
    );
  });

  Matcher refused(HouseholdCryptoError error) => throwsA(
    isA<HouseholdCryptoException>().having((e) => e.error, 'error', error),
  );

  group('key wrapping', () {
    test(
      'only the recipient unwraps, and only from the real wrapper',
      () async {
        final key = HouseholdCrypto.newHouseholdKey(random);
        final wrapped = await HouseholdCrypto.wrapKey(
          householdKey: key,
          wrapper: alice,
          recipientPublicKey: bob.publicKey,
          context: 'h/1/a/b',
        );
        expect(
          await HouseholdCrypto.unwrapKey(
            wrapped: wrapped,
            recipient: bob,
            wrapperPublicKey: alice.publicKey,
            context: 'h/1/a/b',
          ),
          key,
        );
        // Someone else's key.
        await expectLater(
          HouseholdCrypto.unwrapKey(
            wrapped: wrapped,
            recipient: mallory,
            wrapperPublicKey: alice.publicKey,
            context: 'h/1/a/b',
          ),
          refused(HouseholdCryptoError.notAuthentic),
        );
        // A wrapper the recipient did not verify (e.g. one the server swapped
        // in) does not authenticate.
        await expectLater(
          HouseholdCrypto.unwrapKey(
            wrapped: wrapped,
            recipient: bob,
            wrapperPublicKey: mallory.publicKey,
            context: 'h/1/a/b',
          ),
          refused(HouseholdCryptoError.notAuthentic),
        );
        // Moved to another household, epoch or member.
        await expectLater(
          HouseholdCrypto.unwrapKey(
            wrapped: wrapped,
            recipient: bob,
            wrapperPublicKey: alice.publicKey,
            context: 'h/2/a/b',
          ),
          refused(HouseholdCryptoError.notAuthentic),
        );
      },
    );

    test('a changed or cut wrapped key is refused', () async {
      final wrapped = await HouseholdCrypto.wrapKey(
        householdKey: HouseholdCrypto.newHouseholdKey(random),
        wrapper: alice,
        recipientPublicKey: bob.publicKey,
        context: 'c',
      );
      final changed = List.of(wrapped)..[50] ^= 1;
      await expectLater(
        HouseholdCrypto.unwrapKey(
          wrapped: changed,
          recipient: bob,
          wrapperPublicKey: alice.publicKey,
          context: 'c',
        ),
        refused(HouseholdCryptoError.notAuthentic),
      );
      await expectLater(
        HouseholdCrypto.unwrapKey(
          wrapped: wrapped.sublist(0, 40),
          recipient: bob,
          wrapperPublicKey: alice.publicKey,
          context: 'c',
        ),
        refused(HouseholdCryptoError.unsupported),
      );
    });

    test('a low-order public key is refused', () async {
      await expectLater(
        HouseholdCrypto.wrapKey(
          householdKey: HouseholdCrypto.newHouseholdKey(random),
          wrapper: alice,
          recipientPublicKey: List.filled(32, 0),
          context: 'c',
        ),
        refused(HouseholdCryptoError.notAuthentic),
      );
    });

    test(
      'rotation: a new epoch key opens nothing of the old, and back',
      () async {
        final old = HouseholdCrypto.newHouseholdKey(random);
        final next = HouseholdCrypto.newHouseholdKey(random);
        final encrypted = await BackupCipher.withSecret(
          next,
        ).encryptBytes([1, 2, 3], context: 'log/2');
        await expectLater(
          BackupCipher.withSecret(
            old,
          ).decryptBytes(encrypted, context: 'log/2'),
          throwsA(isA<BackupDecryptionException>()),
        );
        expect(
          await BackupCipher.withSecret(
            next,
          ).decryptBytes(encrypted, context: 'log/2'),
          [1, 2, 3],
        );
      },
    );
  });

  group('invitations and attestations', () {
    test('a code round-trips and names the invitation', () async {
      final code = InviteCode.generate(random);
      final parsed = InviteCode.parse(code.format().toLowerCase());
      expect(parsed, code);
      expect(
        await HouseholdCrypto.inviteId(parsed),
        await HouseholdCrypto.inviteId(code),
      );
      expect(await HouseholdCrypto.inviteId(code), hasLength(32));
      expect(InviteCode.fromBytes(code.bytes), code);
      expect(code.toString(), isNot(contains(code.format())));
      expect(() => InviteCode.parse('ABCD'), throwsFormatException);
    });

    test('a MAC checks only for the same secret and the same parts', () async {
      final secret = InviteCode.generate(random).bytes;
      final mac = await HouseholdCrypto.mac(secret, 'p', [
        'a',
        'b',
        [1, 2],
      ]);
      expect(
        await HouseholdCrypto.verifyMac(secret, 'p', [
          'a',
          'b',
          [1, 2],
        ], mac),
        isTrue,
      );
      expect(
        await HouseholdCrypto.verifyMac(secret, 'q', [
          'a',
          'b',
          [1, 2],
        ], mac),
        isFalse,
      );
      expect(
        await HouseholdCrypto.verifyMac(secret, 'p', [
          'ab',
          '',
          [1, 2],
        ], mac),
        isFalse,
      );
      expect(
        await HouseholdCrypto.verifyMac(
          InviteCode.generate(random).bytes,
          'p',
          [
            'a',
            'b',
            [1, 2],
          ],
          mac,
        ),
        isFalse,
      );
    });

    test('fingerprints are short, stable and differ per key', () {
      final a = HouseholdCrypto.fingerprint(alice.publicKey);
      expect(a, matches(RegExp(r'^[0-9A-Z]{4}( [0-9A-Z]{4}){3}$')));
      expect(HouseholdCrypto.fingerprint(alice.publicKey), a);
      expect(HouseholdCrypto.fingerprint(bob.publicKey), isNot(a));
    });

    test('keys never show in toString', () {
      expect(alice.toString(), 'IdentityKeyPair(…)');
    });
  });
}
