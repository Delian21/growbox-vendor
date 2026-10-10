import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the Flutter SDK's Roboto into the current binding so text metrics
/// match production instead of flutter_test's square-glyph Ahem fallback,
/// which wraps every string and fakes layout overflows.
///
/// Must be awaited inside `tester.runAsync` — real file/font IO does not
/// complete under the widget test's FakeAsync zone.
Future<void> loadRoboto() async {
  // Walk up from the test VM (flutter_tester.exe lives deep in the SDK
  // artifacts tree) until the SDK's material_fonts directory is found.
  var cur = Directory(File(Platform.resolvedExecutable).parent.path);
  Directory? fontDir;
  var hops = 0;
  while (fontDir == null) {
    if (++hops > 24) {
      throw StateError('SDK material_fonts not found above ${cur.path}');
    }
    for (final cand in [
      '${cur.path}/cache/artifacts/material_fonts',
      '${cur.path}/artifacts/material_fonts',
    ]) {
      if (Directory(cand).existsSync()) {
        fontDir = Directory(cand);
        break;
      }
    }
    if (fontDir != null) break;
    final next = cur.parent;
    if (next.path == cur.path) {
      throw StateError('SDK material_fonts not found above ${cur.path}');
    }
    cur = next;
  }

  final loader = FontLoader('Roboto');
  for (final file in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final path = '${fontDir.path}/$file';
    if (!File(path).existsSync()) {
      throw StateError('missing SDK font: $path');
    }
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes)));
  }
  await loader.load();
}
