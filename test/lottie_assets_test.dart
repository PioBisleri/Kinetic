import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// Tier-0 bundled animations must parse with the real Lottie engine —
/// these files are hand-authored, so a schema slip would otherwise only
/// show up as a silent placeholder on-device.
void main() {
  test('every bundled Tier-0 Lottie asset parses', () async {
    final files = Directory('assets/anim')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(4), reason: 'press/squat/pull/hinge expected');

    for (final file in files) {
      final composition =
          await LottieComposition.fromBytes(file.readAsBytesSync());
      expect(composition.layers, isNotEmpty, reason: file.path);
      expect(
        composition.endFrame,
        greaterThan(composition.startFrame),
        reason: file.path,
      );
    }
  });
}
