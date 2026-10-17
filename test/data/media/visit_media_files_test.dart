import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/visit_media.dart';

import '../../helpers/fake_media.dart';

Matcher failsWith(MediaFileError error) =>
    throwsA(isA<MediaFileException>().having((e) => e.error, 'error', error));

void main() {
  group('MediaFileValidator', () {
    VisitMediaKind check(String name, List<int> bytes, [int? length]) =>
        MediaFileValidator.validate(
          name: name,
          length: length ?? bytes.length,
          header: bytes.take(MediaFileValidator.headerLength).toList(),
        );

    test('accepts photos and videos whose content matches', () {
      expect(check('a.jpg', fakeJpeg()), VisitMediaKind.photo);
      expect(check('a.JPEG', fakeJpeg()), VisitMediaKind.photo);
      expect(
        check('a.png', [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]),
        VisitMediaKind.photo,
      );
      expect(
        check('a.webp', [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]),
        VisitMediaKind.photo,
      );
      expect(
        check('a.heic', [0, 0, 0, 24, ...'ftypheic'.codeUnits, 0]),
        VisitMediaKind.photo,
      );
      expect(check('a.mp4', fakeMp4()), VisitMediaKind.video);
      expect(check('a.MOV', fakeMp4()), VisitMediaKind.video);
      expect(
        check('a.mov', [0, 0, 0, 8, ...'moov'.codeUnits, 0]),
        VisitMediaKind.video,
      );
    });

    test('rejects unknown extensions, even with valid content', () {
      expect(
        () => check('a.exe', fakeJpeg()),
        failsWith(MediaFileError.unsupportedType),
      );
      expect(
        () => check('noextension', fakeJpeg()),
        failsWith(MediaFileError.unsupportedType),
      );
      expect(
        () => check('a.gif', fakeJpeg()),
        failsWith(MediaFileError.unsupportedType),
      );
    });

    test('rejects content that does not match the extension', () {
      expect(
        () => check('a.jpg', fakeText()),
        failsWith(MediaFileError.unsupportedType),
      );
      expect(
        () => check('a.jpg', fakeMp4()),
        failsWith(MediaFileError.unsupportedType),
      );
      expect(
        () => check('a.mp4', fakeJpeg()),
        failsWith(MediaFileError.unsupportedType),
      );
      // A HEIF photo renamed to a video.
      expect(
        () => check('a.mp4', [0, 0, 0, 24, ...'ftypheic'.codeUnits, 0]),
        failsWith(MediaFileError.unsupportedType),
      );
    });

    test('enforces the size limit of each kind', () {
      expect(
        check('a.jpg', fakeJpeg(), MediaFileValidator.maxPhotoBytes),
        VisitMediaKind.photo,
      );
      expect(
        () => check('a.jpg', fakeJpeg(), MediaFileValidator.maxPhotoBytes + 1),
        failsWith(MediaFileError.tooLarge),
      );
      expect(
        check('a.mp4', fakeMp4(), MediaFileValidator.maxVideoBytes),
        VisitMediaKind.video,
      );
      expect(
        () => check('a.mp4', fakeMp4(), MediaFileValidator.maxVideoBytes + 1),
        failsWith(MediaFileError.tooLarge),
      );
    });

    test('rejects empty files', () {
      expect(
        () => check('a.jpg', const [], 0),
        failsWith(MediaFileError.unreadable),
      );
    });

    test('errors never reveal the file name', () {
      expect(
        const MediaFileException(MediaFileError.tooLarge).toString(),
        'MediaFileException(tooLarge)',
      );
    });
  });

  group('PrivateVisitMediaFileStore', () {
    late Directory temp;
    late Directory storage;
    late PrivateVisitMediaFileStore store;
    var nextName = 0;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('mydr_media_test');
      storage = Directory('${temp.path}/visit_media');
      store = PrivateVisitMediaFileStore(
        locateDirectory: () async => storage,
        createName: () => 'name-${nextName++}',
      );
    });

    tearDown(() => temp.deleteSync(recursive: true));

    File source(String name, List<int> bytes) =>
        File('${temp.path}/$name')..writeAsBytesSync(bytes);

    List<String> stored() => storage.existsSync()
        ? [for (final f in storage.listSync()) f.uri.pathSegments.last]
        : const [];

    test(
      'copies a valid file under a new random name, leaving the source',
      () async {
        final picked = source('rash.JPG', fakeJpeg());

        final result = await store.import(picked.path);

        expect(result.kind, VisitMediaKind.photo);
        expect(result.byteSize, picked.lengthSync());
        expect(result.fileName, matches(RegExp(r'^name-\d+\.jpg$')));
        expect(stored(), [result.fileName]);
        expect(
          await store.readBytes(result.fileName),
          picked.readAsBytesSync(),
        );
        expect(picked.existsSync(), isTrue);
      },
    );

    test('rejects a disguised or missing file and stores nothing', () async {
      await expectLater(
        store.import(source('fake.jpg', fakeText()).path),
        failsWith(MediaFileError.unsupportedType),
      );
      await expectLater(
        store.import('${temp.path}/missing.jpg'),
        failsWith(MediaFileError.unreadable),
      );
      await expectLater(
        store.import(source('empty.jpg', const []).path),
        failsWith(MediaFileError.unreadable),
      );
      expect(stored(), isEmpty);
    });

    test('a missing or damaged stored file reads as null', () async {
      expect(await store.readBytes('name-99.jpg'), isNull);
      expect(await store.localFile('name-99.mp4'), isNull);
    });

    test('never reaches outside its directory', () async {
      final outside = source('outside.jpg', fakeJpeg());
      expect(await store.readBytes('../outside.jpg'), isNull);
      expect(await store.localFile('../outside.jpg'), isNull);
      expect(await store.delete('../outside.jpg'), isFalse);
      expect(await store.delete(outside.path), isFalse);
      expect(outside.existsSync(), isTrue);
    });

    test('deletes a stored file; deleting again is harmless', () async {
      final result = await store.import(source('a.mp4', fakeMp4()).path);

      expect(await store.delete(result.fileName), isTrue);
      expect(stored(), isEmpty);
      expect(await store.delete(result.fileName), isTrue);
    });

    test('clean-up removes only unreferenced files', () async {
      final kept = await store.import(source('a.jpg', fakeJpeg()).path);
      final orphan = await store.import(source('b.jpg', fakeJpeg()).path);

      await store.deleteUnreferenced({kept.fileName});

      expect(stored(), [kept.fileName]);
      expect(stored(), isNot(contains(orphan.fileName)));
    });

    test('deleteVisitMediaFiles keeps going past failures', () async {
      final a = await store.import(source('a.jpg', fakeJpeg()).path);
      final b = await store.import(source('b.jpg', fakeJpeg()).path);

      await deleteVisitMediaFiles(store, ['../nope', a.fileName, b.fileName]);

      expect(stored(), isEmpty);
    });
  });
}
