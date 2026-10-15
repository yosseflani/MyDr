import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';

/// Returns [pack] or throws [error], optionally waiting for [gate].
class FakeFirstAidRepository implements FirstAidRepository {
  FakeFirstAidRepository([this.pack]);

  FirstAidContentPack? pack;
  Object? error;
  Completer<void>? gate;
  int loads = 0;

  @override
  Future<FirstAidContentPack> load() async {
    loads++;
    await gate?.future;
    if (error case final error?) throw error;
    return pack!;
  }
}

/// The bundled Hebrew content, read from disk and checked by the real parser.
FirstAidContentPack bundledHebrewContent() => FirstAidContentParser(
  clock: () => DateTime(2026, 10, 15),
).parse(File('assets/first_aid/he.json').readAsStringSync());

/// Serves [content] as every asset, or fails to load if it is null.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.content);

  final String? content;

  @override
  Future<ByteData> load(String key) async {
    final content = this.content;
    if (content == null) throw FlutterError('no such asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = this.content;
    if (content == null) throw FlutterError('no such asset: $key');
    return content;
  }
}
