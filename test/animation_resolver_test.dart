import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/features/routines/application/animation_resolver.dart';

void main() {
  late Directory cacheDir;

  setUp(() {
    cacheDir = Directory.systemTemp.createTempSync('kinetic_anim_test');
  });

  tearDown(() {
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  });

  Future<void> failDownload(String url, File dest) async {
    throw const SocketException('offline');
  }

  test('kind none or empty ref resolves to none', () async {
    final resolver = AnimationResolver(cacheDir: cacheDir, downloader: failDownload);

    expect((await resolver.resolve(kind: 'none')).source,
        AnimationSource.none);
    expect(
        (await resolver.resolve(kind: 'lottie', ref: '')).source,
        AnimationSource.none);
    expect((await resolver.resolve(kind: 'lottie')).source,
        AnimationSource.none);
  });

  test('Tier-0 asset refs pass through and normalize', () async {
    final resolver = AnimationResolver(cacheDir: cacheDir, downloader: failDownload);

    final full = await resolver.resolve(
      kind: 'lottie',
      ref: 'assets/anim/press.json',
    );
    expect(full.source, AnimationSource.asset);
    expect(full.assetPath, 'assets/anim/press.json');

    // Seeds/custom forms may store a bare name — normalized either way.
    final bare =
        await resolver.resolve(kind: 'lottie', ref: 'squat');
    expect(bare.source, AnimationSource.asset);
    expect(bare.assetPath, 'assets/anim/squat.json');
  });

  test('Tier-1 URL: cache hit served without re-downloading', () async {
    var downloads = 0;
    Future<void> firstDownload(String url, File dest) async {
      downloads++;
      await dest.writeAsString('{"v":"5.7.4"}');
    }

    final warm = AnimationResolver(cacheDir: cacheDir, downloader: firstDownload);
    final first = await warm.resolve(
      kind: 'lottie_url',
      ref: 'https://cdn.example.com/anim.json',
    );
    expect(first.source, AnimationSource.cached);
    expect(first.file!.readAsStringSync(), '{"v":"5.7.4"}');
    expect(downloads, 1);

    // A cold resolver (different downloader that would fail) still finds
    // the cached file.
    final cold = AnimationResolver(cacheDir: cacheDir, downloader: failDownload);
    final second = await cold.resolve(
      kind: 'lottie_url',
      ref: 'https://cdn.example.com/anim.json',
    );
    expect(second.source, AnimationSource.cached);
    expect(second.file!.path, first.file!.path);
    expect(downloads, 1);
  });

  test('Tier-1 download failure degrades to needsDownload', () async {
    final resolver = AnimationResolver(cacheDir: cacheDir, downloader: failDownload);
    final resolved = await resolver.resolve(
      kind: 'lottie_url',
      ref: 'https://cdn.example.com/missing.json',
    );
    expect(resolved.source, AnimationSource.needsDownload);
    expect(resolved.url, 'https://cdn.example.com/missing.json');
  });

  test('Tier-1 without a cache dir never touches the network', () async {
    var downloads = 0;
    final resolver = AnimationResolver(
      cacheDir: null,
      downloader: (url, dest) async => downloads++,
    );
    final resolved = await resolver.resolve(
      kind: 'lottie_url',
      ref: 'https://cdn.example.com/anim.json',
    );
    expect(resolved.source, AnimationSource.needsDownload);
    expect(downloads, 0);
  });

  test('non-http animation refs resolve to none', () async {
    final resolver = AnimationResolver(cacheDir: cacheDir, downloader: failDownload);
    expect(
      (await resolver.resolve(kind: 'lottie_url', ref: 'file:///etc/passwd'))
          .source,
      AnimationSource.none,
    );
    expect(
      (await resolver.resolve(kind: 'lottie_url', ref: 'not a url')).source,
      AnimationSource.none,
    );
  });
}
