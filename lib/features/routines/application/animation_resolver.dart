import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where an exercise's animation resolved to.
enum AnimationSource {
  /// No animation configured (or an unusable ref).
  none,

  /// Tier-0: bundled asset, plays fully offline.
  asset,

  /// Tier-1: previously downloaded file in the local cache.
  cached,

  /// Tier-1: a URL animation that isn't cached yet (offline, or the
  /// download failed) — the UI shows a placeholder until it succeeds.
  needsDownload,
}

class ResolvedAnimation {
  const ResolvedAnimation({
    required this.source,
    this.assetPath,
    this.file,
    this.url,
  });

  final AnimationSource source;

  /// Set when [source] is [AnimationSource.asset].
  final String? assetPath;

  /// Set when [source] is [AnimationSource.cached].
  final File? file;

  /// Original URL for [AnimationSource.cached] / [AnimationSource.needsDownload].
  final String? url;
}

/// Downloads a Tier-1 animation into [dest]. Injectable so tests can fake
/// the network without touching sockets.
typedef AnimationDownloader = Future<void> Function(String url, File dest);

/// Lazily provides the cache directory. Called only when a Tier-1 URL
/// actually needs resolving — platform-channel futures (path_provider)
/// never complete inside a FakeAsync `testWidgets` body, so Tier-0/none
/// paths must never await one.
typedef CacheDirLookup = Future<Directory?> Function();

/// Resolves `animationKind`/`animationRef` on an [Exercise]-shaped input to
/// something the player can render.
class AnimationResolver {
  AnimationResolver({
    this.cacheDir,
    this.cacheDirLookup,
    AnimationDownloader? downloader,
  }) : _download = downloader ?? downloadAnimation;

  /// Direct cache directory (tests); wins over [cacheDirLookup].
  final Directory? cacheDir;

  /// Lazy cache-directory lookup for the app (see [CacheDirLookup]).
  final CacheDirLookup? cacheDirLookup;
  final AnimationDownloader _download;

  Future<Directory?> _resolveCacheDir() async {
    if (cacheDir != null) return cacheDir;
    final lookup = cacheDirLookup;
    if (lookup == null) return null;
    try {
      return await lookup();
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedAnimation> resolve({
    required String kind,
    String? ref,
  }) async {
    if (ref == null || ref.isEmpty || kind == 'none') {
      return const ResolvedAnimation(source: AnimationSource.none);
    }

    switch (kind) {
      case 'lottie':
        // Tier-0: bundled asset. Seeds may store either the full asset
        // path or a bare name like "press".
        final path = ref.startsWith('assets/')
            ? ref
            : 'assets/anim/${ref.replaceAll(RegExp(r'\.json$'), '')}.json';
        return ResolvedAnimation(source: AnimationSource.asset, assetPath: path);

      case 'lottie_url':
        final uri = Uri.tryParse(ref);
        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          return const ResolvedAnimation(source: AnimationSource.none);
        }
        final dir = await _resolveCacheDir();
        if (dir == null) {
          return ResolvedAnimation(source: AnimationSource.needsDownload, url: ref);
        }
        final file = File('${dir.path}/${cacheKeyFor(ref)}');
        if (await file.exists()) {
          return ResolvedAnimation(
            source: AnimationSource.cached,
            file: file,
            url: ref,
          );
        }
        try {
          await dir.create(recursive: true);
          await _download(ref, file);
          return ResolvedAnimation(
            source: AnimationSource.cached,
            file: file,
            url: ref,
          );
        } catch (_) {
          // Offline or bad URL — degrade to the offline placeholder; the
          // next resolve retries the download.
          return ResolvedAnimation(source: AnimationSource.needsDownload, url: ref);
        }

      default:
        return const ResolvedAnimation(source: AnimationSource.none);
    }
  }

  /// Dependency-free FNV-1a — short, deterministic cache filenames.
  static String cacheKeyFor(String url) {
    var hash = 0x811C9DC5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'anim_${hash.toRadixString(16)}.json';
  }
}

/// Default Tier-1 downloader (dart:io — no extra package).
Future<void> downloadAnimation(String url, File dest) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} for $url');
    }
    final bytes = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    await dest.writeAsBytes(bytes, flush: true);
  } finally {
    client.close(force: true);
  }
}

/// App-document cache directory, resolved lazily so none/Tier-0 animations
/// never await a platform channel (those futures hang in FakeAsync widget
/// tests — see CacheDirLookup).
final animationResolverProvider = Provider<AnimationResolver>(
  (ref) => AnimationResolver(
    cacheDirLookup: () async {
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}/anim_cache');
    },
  ),
);

/// Resolved animation for one (kind, ref) pair — watched by the player
/// widget; keyed on the ref so edits invalidate immediately.
final resolvedAnimationProvider = FutureProvider.autoDispose
    .family<ResolvedAnimation, ({String kind, String? ref})>(
  (ref, args) {
    final resolver = ref.watch(animationResolverProvider);
    return resolver.resolve(kind: args.kind, ref: args.ref);
  },
);
