/// Ranked, typo-tolerant search over the exercise catalog.
///
/// Pure Dart — no SQL, no Flutter — so ranking is unit-testable and both
/// the Exercise Library and the add-exercise sheet share one implementation.
/// Rules:
///
/// * Everything is lowercased; punctuation splits words; a trailing
///   plural "s" is folded (`curls` finds `curl`, but `press` stays `press`).
/// * Query tokens are AND-ed: every token must land on some field
///   (name, muscle, category — directly or through a synonym), otherwise
///   the row is dropped.
/// * Per-token relation tiers, best wins: exact word (800) > word prefix
///   (650) > substring (500) > fuzzy with ≤1–2 edits (300). A whole-name
///   exact match scores 1000, a name prefix 850.
/// * Muscle, category and synonym hits take a 150-point penalty each so a
///   name match always outranks a metadata match at the same tier.
/// * Ties break on shorter name, then alphabetically; an empty query
///   returns the input untouched.
library;

import '../database/database.dart';

const _nameExact = 1000;
const _namePrefix = 850;
const _wordExact = 800;
const _wordPrefix = 650;
const _substring = 500;
const _fuzzy = 300;
const _metaPenalty = 150;

/// Gym slang ↔ canonical words (directionless). Members are plural-folded
/// before wiring, so `{'calve', 'calf'}` also serves `calves`.
const _synonymGroups = <Set<String>>{
  {'ohp', 'overhead'},
  {'dl', 'deadlift'},
  {'rdl', 'romanian'},
  {'pec', 'chest'},
  {'delt', 'shoulder'},
  {'trap', 'trapezius'},
  {'bi', 'bicep'},
  {'tri', 'tricep'},
  {'ham', 'hamstring'},
  {'calve', 'calf'},
  {'ab', 'core'},
};

/// Folded once at startup: canonical word → its interchangeable siblings.
final Map<String, Set<String>> _synonyms = () {
  final map = <String, Set<String>>{};
  for (final group in _synonymGroups) {
    final canonical = {for (final w in group) _foldPlural(w)};
    for (final w in canonical) {
      map.putIfAbsent(w, () => <String>{}).addAll(canonical.difference({w}));
    }
  }
  return map;
}();

/// Lowercase + drop one trailing plural "s" (`press` and `leg` are kept).
String _foldPlural(String word) {
  var w = word.toLowerCase();
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
    w = w.substring(0, w.length - 1);
  }
  return w;
}

/// Split any text into folded word tokens (also used for the query).
List<String> _words(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .map(_foldPlural)
    .toList();

/// Levenshtein distance, giving up once every cell row exceeds [max].
int _levenshtein(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  var prev = [for (var j = 0; j <= b.length; j++) j];
  for (var i = 1; i <= a.length; i++) {
    final curr = <int>[i];
    var rowMin = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final v = [
        prev[j] + 1, // deletion
        curr[j - 1] + 1, // insertion
        prev[j - 1] + cost, // substitution
      ].reduce((x, y) => x < y ? x : y);
      curr.add(v);
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    prev = curr;
  }
  return prev[b.length];
}

/// How one token relates to one field's text — its tier, or null for
/// no match at all.
int? _relation(String token, String rawLower, List<String> words) {
  if (rawLower == token) return _nameExact;
  if (rawLower.startsWith('$token ')) return _namePrefix;
  if (rawLower.contains(token)) {
    for (final w in words) {
      if (w == token) return _wordExact;
      if (w.startsWith(token)) return _wordPrefix;
    }
    return _substring;
  }
  // Whole-field substring failed → allow small typos on single words.
  final max = token.length <= 4 ? 1 : 2;
  for (final w in words) {
    if ((w.length - token.length).abs() > max) continue;
    if (_levenshtein(token, w, max) <= max) return _fuzzy;
  }
  return null;
}

int? _best(int? current, int? candidate) => candidate == null
    ? current
    : (current == null || candidate > current ? candidate : current);

/// Score one token against a row: direct name, then penalised muscle /
/// category, then penalised synonyms (double-penalised when the synonym
/// itself only lands on metadata). Null → the token doesn't match.
int? _scoreToken(
  String token,
  String name,
  List<String> nameWords,
  String meta,
  List<String> metaWords,
) {
  var best = _relation(token, name, nameWords);
  best = _best(best, _hit(() => _relation(token, meta, metaWords), _metaPenalty));

  for (final alt in _synonyms[token] ?? const <String>{}) {
    best = _best(best, _hit(() => _relation(alt, name, nameWords), _metaPenalty));
    best =
        _best(best, _hit(() => _relation(alt, meta, metaWords), 2 * _metaPenalty));
  }
  return best;
}

int? _hit(int? Function() relation, int penalty) {
  final r = relation();
  return r == null ? null : r - penalty;
}

/// Filters and ranks [rows] against [query] (see the library docs).
/// [muscle] and [category] receive a penalty so name matches outrank them.
List<T> rankMatches<T>(
  String query,
  List<T> rows, {
  required String Function(T row) name,
  String Function(T row)? muscle,
  String Function(T row)? category,
}) {
  final tokens = _words(query).toSet().toList(); // dedupe, keep order
  if (tokens.isEmpty) return rows;

  final scored = <({int score, String key, T row})>[];
  for (final row in rows) {
    final displayName = name(row);
    final nameLower = displayName.toLowerCase();
    final nameWords = _words(displayName);
    final meta =
        '${muscle?.call(row) ?? ''} ${category?.call(row) ?? ''}'
            .toLowerCase(); // _relation() compares case-sensitively
    final metaWords = _words(meta);

    var total = 0;
    var andMatched = true;
    for (final token in tokens) {
      final s = _scoreToken(token, nameLower, nameWords, meta, metaWords);
      if (s == null) {
        andMatched = false;
        break;
      }
      total += s;
    }
    if (andMatched) scored.add((score: total, key: nameLower, row: row));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = a.key.length.compareTo(b.key.length);
    if (byLength != 0) return byLength;
    return a.key.compareTo(b.key);
  });
  return [for (final s in scored) s.row];
}

/// One-call catalog search: ranks exercise rows by name, muscle and
/// category, using [muscleNames] to resolve `primaryMuscleId` to a
/// human-readable muscle (falls back to the id with underscores spaced).
List<Exercise> searchCatalog(
  List<Exercise> rows,
  String query, {
  Map<String, String> muscleNames = const {},
}) =>
    rankMatches<Exercise>(
      query,
      rows,
      name: (e) => e.name,
      muscle: (e) => muscleNames[e.primaryMuscleId] ??
          e.primaryMuscleId.replaceAll('_', ' '),
      category: (e) => e.category,
    );
