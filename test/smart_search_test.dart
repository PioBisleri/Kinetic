import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/search/smart_search.dart';

Exercise _exercise(
  String id,
  String name, {
  String category = 'custom',
  String muscle = 'chest',
}) =>
    Exercise(
      updatedAt: DateTime.utc(2026, 1, 1),
      id: id,
      name: name,
      mechanics: 'compound',
      category: category,
      primaryMuscleId: muscle,
      equipment: '[]',
      defaultMetric: 'weight_reps',
      animationKind: 'none',
      isCustom: false,
    );

List<String> _names(List<Exercise> rows) => [for (final e in rows) e.name];

void main() {
  final catalog = [
    _exercise('e1', 'Bench', category: 'barbell'),
    _exercise('e2', 'Bench Press', category: 'barbell'),
    _exercise('e3', 'Incline Barbell Bench Press', category: 'barbell'),
    _exercise('e4', 'Benchpress', category: 'custom'),
    _exercise('e5', 'Prebench Support', category: 'custom'),
    _exercise('e6', 'Bnch Machine', category: 'machine'),
    _exercise('e7', 'Treadmill Run',
        category: 'cardio', muscle: 'quadriceps'),
    _exercise('e8', 'Plank', category: 'bodyweight', muscle: 'abdominals'),
    _exercise('e9', 'Barbell Row',
        category: 'barbell', muscle: 'latissimus_dorsi'),
    _exercise('e10', 'Barbell Overhead Press',
        category: 'barbell', muscle: 'shoulders'),
    _exercise('e11', 'Dumbbell Bicep Curl',
        category: 'dumbbell', muscle: 'biceps'),
    _exercise('e12', 'Incline Dumbbell Press', category: 'dumbbell'),
  ];

  List<String> run(String query) =>
      _names(searchCatalog(catalog, query, muscleNames: const {
        'latissimus_dorsi': 'Latissimus Dorsi',
      }));

  test(
      'tiers order exact > name prefix > word exact > word prefix > '
      'substring > fuzzy', () {
    expect(run('bench'), [
      'Bench', // whole-name exact (1000)
      'Bench Press', // name prefix (850)
      'Incline Barbell Bench Press', // exact word (800)
      'Benchpress', // word prefix (650)
      'Prebench Support', // mid-word substring (500)
      'Bnch Machine', // fuzzy, 1 edit (300)
    ]);
  });

  test('query is case-insensitive and matches the tier order too', () {
    expect(run('BENCH'), run('bench'));
  });

  test('tokens are AND-ed — every token must land somewhere', () {
    expect(run('incline bench'), ['Incline Barbell Bench Press']);
    // Incline Press has no bench anywhere (fuzzy can't bridge it); the
    // two survivors tie on score, so the shorter name wins.
    expect(run('incline press'), [
      'Incline Dumbbell Press',
      'Incline Barbell Bench Press',
    ]);
  });

  test('category and muscle names match with a metadata penalty', () {
    // No exercise name contains "cardio" — the category does.
    expect(run('cardio'), ['Treadmill Run']);
    // "lats" plural-folds to "lat" and lands on the muscle name.
    expect(run('lats'), ['Barbell Row']);
  });

  test('synonyms bridge gym slang to the canonical word', () {
    expect(run('ohp'), ['Barbell Overhead Press']);
  });

  test('plurals fold: "curls" finds "curl"', () {
    expect(run('curls'), ['Dumbbell Bicep Curl']);
  });

  test('fuzzy typo + tie-break: equal scores prefer the shorter name', () {
    expect(run('bnch press'), [
      'Bench Press',
      'Incline Barbell Bench Press',
    ]);
  });

  test('an empty query returns the input untouched', () {
    expect(searchCatalog(catalog, '   '), same(catalog));
  });

  test('no match at all yields an empty result', () {
    expect(run('zzz'), isEmpty);
  });
}
