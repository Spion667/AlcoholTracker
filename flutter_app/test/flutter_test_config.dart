import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Laedt die App-Schriften, damit Layout-Tests mit echten Textbreiten laufen
/// (sonst rendert `flutter test` alles in der quadratischen "Ahem"-Schrift).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final path in files) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Inter', ['assets/fonts/Inter-Variable.ttf']);
  await load('Bebas Neue', ['assets/fonts/BebasNeue-Regular.ttf']);
  await load('Space Mono', [
    'assets/fonts/SpaceMono-Regular.ttf',
    'assets/fonts/SpaceMono-Bold.ttf',
  ]);

  await testMain();
}
