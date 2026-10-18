// Checks firebase/storage.rules against the Firebase Local Emulator Suite
// (demo project, no real cloud):
//
//   cd firebase && firebase emulators:start --project demo-mydr --only auth,storage
//   dart run tool/storage_rules_check.dart
//
// Exits with 1 if any rule does not behave as intended.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _auth = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const _storage = 'http://127.0.0.1:9199/v0/b/demo-mydr.appspot.com/o';

final _client = HttpClient();

Future<(int, String)> _call(
  String method,
  String url, {
  List<int>? body,
  String? token,
  String contentType = 'application/json',
}) async {
  final request = await _client.openUrl(method, Uri.parse(url));
  request.headers.set('Content-Type', contentType);
  if (token != null) request.headers.set('Authorization', 'Firebase $token');
  if (body != null) request.add(body);
  final response = await request.close();
  return (response.statusCode, await response.transform(utf8.decoder).join());
}

Future<(String, String)> _newUser() async {
  final email = 'rules-${Random().nextInt(1 << 30)}@example.test';
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
  if (status != 200) throw StateError('Could not create a test user: $body');
  final json = jsonDecode(body) as Map<String, Object?>;
  return (json['localId'] as String, json['idToken'] as String);
}

Future<int> _upload(String path, String? token, {int size = 16}) async {
  final url = '$_storage?uploadType=media&name=${Uri.encodeComponent(path)}';
  return (await _call(
    'POST',
    url,
    body: Uint8List(size),
    token: token,
    contentType: 'application/octet-stream',
  )).$1;
}

Future<int> _download(String path, String? token) async => (await _call(
  'GET',
  '$_storage/${Uri.encodeComponent(path)}?alt=media',
  token: token,
)).$1;

Future<int> _list(String prefix, String? token) async => (await _call(
  'GET',
  '$_storage?prefix=${Uri.encodeComponent(prefix)}&delimiter=%2F',
  token: token,
)).$1;

Future<int> _delete(String path, String? token) async => (await _call(
  'DELETE',
  '$_storage/${Uri.encodeComponent(path)}',
  token: token,
)).$1;

bool _refused(int status) => status == 401 || status == 403;

Future<void> main() async {
  final (aUid, a) = await _newUser();
  final (_, b) = await _newUser();
  final own = 'users/$aUid/backups/b1/data.bin';

  final checks = <String, bool>{
    'owner uploads an object to their own folder': await _upload(own, a) == 200,
    'owner downloads it': await _download(own, a) == 200,
    'owner lists their backups': await _list('users/$aUid/backups/', a) == 200,
    'owner cannot overwrite an object': _refused(await _upload(own, a)),
    'an object over 200 MB is refused': _refused(
      await _upload(
        'users/$aUid/backups/b1/big.bin',
        a,
        size: 200 * 1024 * 1024 + 1,
      ),
    ),
    'another account cannot download': _refused(await _download(own, b)),
    'another account cannot list': _refused(
      await _list('users/$aUid/backups/', b),
    ),
    'another account cannot write into the folder': _refused(
      await _upload('users/$aUid/backups/b1/other.bin', b),
    ),
    'another account cannot delete': _refused(await _delete(own, b)),
    'signed out cannot download': _refused(await _download(own, null)),
    'nothing can be stored outside users/{uid}/backups': _refused(
      await _upload('public/$aUid.bin', a),
    ),
    'owner deletes their object': (await _delete(own, a)) < 300,
  };

  _client.close();
  for (final MapEntry(key: name, value: passed) in checks.entries) {
    stdout.writeln('${passed ? 'PASS' : 'FAIL'}  $name');
  }
  final allPassed = checks.values.every((passed) => passed);
  stdout.writeln(
    allPassed ? 'All storage rule checks passed.' : 'Some checks FAILED.',
  );
  exit(allPassed ? 0 : 1);
}
