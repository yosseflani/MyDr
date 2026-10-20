// Checks firebase/firestore.rules and the household part of
// firebase/storage.rules against the Firebase Local Emulator Suite (demo
// project, no real cloud, fictional bytes only):
//
//   cd firebase && firebase emulators:start --project demo-mydr --only auth,firestore,storage
//   dart run tool/household_rules_check.dart
//
// Writes go through the emulator's REST `commit` endpoint, which applies a
// batch atomically like the app's SDK does. Exits with 1 if any rule does
// not behave as intended.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _project = 'demo-mydr';
const _auth = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const _root = 'projects/$_project/databases/(default)/documents';
const _firestore = 'http://127.0.0.1:8080/v1/$_root';
const _storage = 'http://127.0.0.1:9199/v0/b/$_project.appspot.com/o';

final _client = HttpClient();
final _random = Random();

Future<(int, String)> _call(
  String method,
  String url, {
  List<int>? body,
  String? token,
  String contentType = 'application/json',
  bool bearer = true,
}) async {
  final request = await _client.openUrl(method, Uri.parse(url));
  request.headers.set('Content-Type', contentType);
  if (token != null) {
    request.headers.set(
      'Authorization',
      bearer ? 'Bearer $token' : 'Firebase $token',
    );
  }
  if (body != null) request.add(body);
  final response = await request.close();
  return (response.statusCode, await response.transform(utf8.decoder).join());
}

Future<(String, String)> _newUser() async {
  final email = 'household-${_random.nextInt(1 << 30)}@example.test';
  final (status, body) = await _call(
    'POST',
    '$_auth/accounts:signUp?key=demo',
    body: utf8.encode(
      jsonEncode({
        'email': email,
        'password': 'password123',
        'returnSecureToken': true,
      }),
    ),
  );
  if (status != 200) throw StateError('Could not create a test user');
  final json = jsonDecode(body) as Map<String, Object?>;
  return (json['localId'] as String, json['idToken'] as String);
}

Map<String, Object?> _value(Object? v) => switch (v) {
  null => {'nullValue': null},
  final bool b => {'booleanValue': b},
  final int i => {'integerValue': '$i'},
  final String s => {'stringValue': s},
  final Uint8List bytes => {'bytesValue': base64Encode(bytes)},
  final DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
  _ => throw ArgumentError('unsupported'),
};

Map<String, Object?> _fields(Map<String, Object?> data) => {
  for (final MapEntry(:key, :value) in data.entries) key: _value(value),
};

Map<String, Object?> _set(String path, Map<String, Object?> data) => {
  'update': {'name': '$_root/$path', 'fields': _fields(data)},
};

Map<String, Object?> _patch(String path, Map<String, Object?> data) => {
  'update': {'name': '$_root/$path', 'fields': _fields(data)},
  'updateMask': {'fieldPaths': data.keys.toList()},
  'currentDocument': {'exists': true},
};

Map<String, Object?> _delete(String path) => {'delete': '$_root/$path'};

Future<int> _commit(String? token, List<Map<String, Object?>> writes) async =>
    (await _call(
      'POST',
      '$_firestore:commit',
      body: utf8.encode(jsonEncode({'writes': writes})),
      token: token,
    )).$1;

Future<int> _get(String path, String? token) async =>
    (await _call('GET', '$_firestore/$path', token: token)).$1;

Future<int> _queryInvites(String householdId, String? token) async =>
    (await _call(
      'POST',
      '$_firestore:runQuery',
      token: token,
      body: utf8.encode(
        jsonEncode({
          'structuredQuery': {
            'from': [
              {'collectionId': 'invites'},
            ],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': 'householdId'},
                'op': 'EQUAL',
                'value': {'stringValue': householdId},
              },
            },
          },
        }),
      ),
    )).$1;

Future<int> _upload(String path, String? token) async => (await _call(
  'POST',
  '$_storage?uploadType=media&name=${Uri.encodeComponent(path)}',
  body: Uint8List(32),
  token: token,
  contentType: 'application/octet-stream',
  bearer: false,
)).$1;

Future<int> _download(String path, String? token) async => (await _call(
  'GET',
  '$_storage/${Uri.encodeComponent(path)}?alt=media',
  token: token,
  bearer: false,
)).$1;

bool _ok(int status) => status >= 200 && status < 300;
bool _refused(int status) => status == 401 || status == 403;

Uint8List _bytes(int n) =>
    Uint8List.fromList([for (var i = 0; i < n; i++) _random.nextInt(256)]);

Map<String, Object?> _member(String uid, String role, String addedBy) => {
  'uid': uid,
  'publicKey': _bytes(32),
  'role': role,
  'addedBy': addedBy,
  'attestation': _bytes(32),
  'attestedEpoch': 1,
  'label': null,
};

Map<String, Object?> _key(int epoch, String by) => {
  'epoch': epoch,
  'wrappedBy': by,
  'wrapped': _bytes(93),
};

Future<void> main() async {
  final (aUid, a) = await _newUser();
  final (bUid, b) = await _newUser();
  final (cUid, c) = await _newUser();
  final hid = 'h${_random.nextInt(1 << 30)}';
  final invite = 'i${_random.nextInt(1 << 30)}';
  final expired = 'e${_random.nextInt(1 << 30)}';
  final now = DateTime.now();

  Map<String, Object?> inviteData(DateTime expiresAt) => {
    'householdId': hid,
    'inviterUid': aUid,
    'inviterPublicKey': _bytes(32),
    'inviterMac': _bytes(32),
    'inviterLabel': null,
    'createdAt': now,
    'expiresAt': expiresAt,
    'status': 'open',
  };

  Map<String, Object?> logEntry(String uid, int seq) => {
    'uid': uid,
    'seq': seq,
    'epoch': 1,
    'data': _bytes(64),
  };

  final checks = <String, bool>{};
  Future<void> check(String name, Future<bool> Function() run) async {
    checks[name] = await run();
  }

  await check(
    'a user creates a household as its first admin',
    () async => _ok(
      await _commit(a, [
        _set('households/$hid', {
          'createdBy': aUid,
          'epoch': 1,
          'needsRotation': false,
        }),
        _set('households/$hid/members/$aUid', _member(aUid, 'admin', aUid)),
        _set('households/$hid/members/$aUid/keys/1', _key(1, aUid)),
      ]),
    ),
  );
  await check(
    'nobody can take over an existing household',
    () async => _refused(
      await _commit(c, [
        _set('households/$hid', {
          'createdBy': cUid,
          'epoch': 1,
          'needsRotation': false,
        }),
        _set('households/$hid/members/$cUid', _member(cUid, 'admin', cUid)),
      ]),
    ),
  );
  await check(
    'a non-member cannot read the household',
    () async => _refused(await _get('households/$hid', b)),
  );
  await check(
    'a non-member cannot list the members',
    () async => _refused(await _get('households/$hid/members', b)),
  );
  await check(
    'a non-member cannot add themself',
    () async => _refused(
      await _commit(b, [
        _set('households/$hid/members/$bUid', _member(bUid, 'admin', bUid)),
      ]),
    ),
  );
  await check(
    'signed out cannot read the household',
    () async => _refused(await _get('households/$hid', null)),
  );
  await check(
    'an admin creates an invitation',
    () async => _ok(
      await _commit(a, [
        _set('invites/$invite', inviteData(now.add(const Duration(days: 2)))),
        _set('invites/$expired', inviteData(now.subtract(const Duration(hours: 1)))),
      ]),
    ),
  );
  await check(
    'the invitee reads the invitation by its id',
    () async => _ok(await _get('invites/$invite', b)),
  );
  await check(
    'a non-member cannot list the invitations',
    () async => _refused(await _queryInvites(hid, b)),
  );
  await check(
    'a member lists the invitations',
    () async => _ok(await _queryInvites(hid, a)),
  );
  await check(
    'the invitee cannot change the invitation\'s household or inviter',
    () async => _refused(
      await _commit(b, [
        _patch('invites/$invite', {
          'status': 'accepted',
          'inviteeUid': bUid,
          'householdId': 'other',
        }),
      ]),
    ),
  );
  await check(
    'an expired invitation cannot be accepted',
    () async => _refused(
      await _commit(c, [
        _patch('invites/$expired', {'status': 'accepted', 'inviteeUid': cUid}),
      ]),
    ),
  );
  await check(
    'the invitee accepts with their public key',
    () async => _ok(
      await _commit(b, [
        _patch('invites/$invite', {
          'status': 'accepted',
          'inviteeUid': bUid,
          'inviteePublicKey': _bytes(32),
          'inviteeMac': _bytes(32),
        }),
      ]),
    ),
  );
  await check(
    'an answered invitation cannot be answered again',
    () async => _refused(
      await _commit(c, [
        _patch('invites/$invite', {'status': 'accepted', 'inviteeUid': cUid}),
      ]),
    ),
  );
  await check(
    'the admin adds the invitee with a wrapped key',
    () async => _ok(
      await _commit(a, [
        _set('households/$hid/members/$bUid', _member(bUid, 'member', aUid)),
        _set('households/$hid/members/$bUid/keys/1', _key(1, aUid)),
        _patch('invites/$invite', {'status': 'completed'}),
      ]),
    ),
  );
  await check(
    'a member reads the household',
    () async => _ok(await _get('households/$hid', b)),
  );
  await check(
    'a member reads their own wrapped keys',
    () async => _ok(await _get('households/$hid/members/$bUid/keys', b)),
  );
  await check(
    'a member cannot read another member\'s wrapped keys',
    () async => _refused(await _get('households/$hid/members/$aUid/keys/1', b)),
  );
  await check(
    'a non-admin member cannot invite',
    () async => _refused(
      await _commit(b, [
        _set('invites/x$invite', {...inviteData(now), 'inviterUid': bUid}),
      ]),
    ),
  );
  await check(
    'a non-admin member cannot remove another member',
    () async => _refused(
      await _commit(b, [_delete('households/$hid/members/$aUid')]),
    ),
  );
  await check(
    'a non-admin member cannot make themself admin',
    () async => _refused(
      await _commit(b, [
        _patch('households/$hid/members/$bUid', {'role': 'admin'}),
      ]),
    ),
  );
  final device = 'device-b';
  await check(
    'a member appends the first batch of their device\'s log',
    () async => _ok(
      await _commit(b, [
        _set('households/$hid/devices/$device', {'uid': bUid, 'lastSeq': 1}),
        _set('households/$hid/devices/$device/log/1', logEntry(bUid, 1)),
      ]),
    ),
  );
  await check(
    'a batch can never be overwritten',
    () async => _refused(
      await _commit(b, [
        _set('households/$hid/devices/$device/log/1', logEntry(bUid, 1)),
      ]),
    ),
  );
  await check(
    'a device\'s log cannot skip a batch',
    () async => _refused(
      await _commit(b, [
        _set('households/$hid/devices/$device', {'uid': bUid, 'lastSeq': 3}),
        _set('households/$hid/devices/$device/log/3', logEntry(bUid, 3)),
      ]),
    ),
  );
  await check(
    'another member cannot write into this device\'s log',
    () async => _refused(
      await _commit(a, [
        _set('households/$hid/devices/$device', {'uid': aUid, 'lastSeq': 2}),
        _set('households/$hid/devices/$device/log/2', logEntry(aUid, 2)),
      ]),
    ),
  );
  await check(
    'a member reads the other devices\' logs',
    () async => _ok(await _get('households/$hid/devices/$device/log/1', a)),
  );
  await check(
    'a non-member cannot read the logs',
    () async =>
        _refused(await _get('households/$hid/devices/$device/log/1', c)),
  );

  final media = 'households/$hid/media/m${_random.nextInt(1 << 30)}.bin';
  await check(
    'storage: a member uploads an encrypted photo',
    () async => _ok(await _upload(media, a)),
  );
  await check(
    'storage: another member downloads it',
    () async => _ok(await _download(media, b)),
  );
  await check(
    'storage: a photo can never be overwritten',
    () async => _refused(await _upload(media, b)),
  );
  await check(
    'storage: a non-member cannot download',
    () async => _refused(await _download(media, c)),
  );
  await check(
    'storage: a non-member cannot upload',
    () async => _refused(await _upload('households/$hid/media/c.bin', c)),
  );

  await check(
    'the admin removes a member and starts a new key epoch',
    () async => _ok(
      await _commit(a, [
        _delete('households/$hid/members/$bUid/keys/1'),
        _delete('households/$hid/members/$bUid'),
        _patch('households/$hid', {'epoch': 2, 'needsRotation': false}),
        _set('households/$hid/members/$aUid/keys/2', _key(2, aUid)),
      ]),
    ),
  );
  await check(
    'the removed member cannot read the household any more',
    () async => _refused(await _get('households/$hid', b)),
  );
  await check(
    'the removed member cannot read the logs any more',
    () async =>
        _refused(await _get('households/$hid/devices/$device/log/1', b)),
  );
  await check(
    'the removed member cannot append to the log any more',
    () async => _refused(
      await _commit(b, [
        _set('households/$hid/devices/$device', {'uid': bUid, 'lastSeq': 2}),
        _set('households/$hid/devices/$device/log/2', logEntry(bUid, 2)),
      ]),
    ),
  );
  await check(
    'storage: the removed member cannot download any more',
    () async => _refused(await _download(media, b)),
  );
  await check(
    'the key epoch never goes back',
    () async => _refused(
      await _commit(a, [
        _patch('households/$hid', {'epoch': 1}),
      ]),
    ),
  );

  _client.close();
  for (final MapEntry(key: name, value: passed) in checks.entries) {
    stdout.writeln('${passed ? 'PASS' : 'FAIL'}  $name');
  }
  final allPassed = checks.values.every((passed) => passed);
  stdout.writeln(
    allPassed
        ? 'All ${checks.length} household rule checks passed.'
        : 'Some checks FAILED.',
  );
  exit(allPassed ? 0 : 1);
}
