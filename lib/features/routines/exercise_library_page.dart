import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/search/smart_search.dart';
import '../../core/theme/app_theme.dart';

final exerciseCountProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).exerciseCount(),
);

/// Category filter chips over the seeded exercise catalog.
class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? category) => state = category;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String?>(
        CategoryFilterNotifier.new);

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final db = ref.watch(databaseProvider);
  final category = ref.watch(categoryFilterProvider);
  return db.watchExercises(category: category);
});

const _categories = [
  ('all', 'All'),
  ('barbell', 'Barbell'),
  ('dumbbell', 'Dumbbell'),
  ('machine', 'Machine'),
  ('cable', 'Cable'),
  ('bodyweight', 'Bodyweight'),
  ('cardio', 'Cardio'),
];

/// Full-screen browse/search over the 89-exercise seed catalog.
class ExerciseLibraryPage extends ConsumerStatefulWidget {
  const ExerciseLibraryPage({super.key});

  @override
  ConsumerState<ExerciseLibraryPage> createState() =>
      _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends ConsumerState<ExerciseLibraryPage> {
  final _searchCtrl = TextEditingController();

  /// Kept as plain state (not a provider): nothing outside this page
  /// reads it, and the route stays mounted across detail navigation.
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    final filter = ref.watch(categoryFilterProvider);
    final count = ref.watch(exerciseCountProvider);
    final muscleNames = ref.watch(muscleNamesProvider);
    // Ranked once for both the count row and the list; null while the
    // catalog stream is still loading.
    final ranked = switch (exercises) {
      AsyncData(:final value) =>
        searchCatalog(value, _query, muscleNames: muscleNames),
      _ => null,
    };
    final String countText;
    if (_query.isEmpty) {
      countText = switch (count) {
        AsyncData(:final value) => '$value exercises',
        _ => 'Loading…',
      };
    } else {
      countText = ranked == null ? 'Searching…' : '${ranked.length} matches';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      floatingActionButton: FloatingActionButton(
        key: const Key('create-exercise'),
        tooltip: 'New exercise',
        onPressed: () => context.push('/library/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('library-search'),
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('library-search-clear'),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            // SingleChildScrollView + Row (not ListView.builder): only 7
            // static chips — eager build guarantees they all exist.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < _categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Builder(builder: (context) {
                      final (id, label) = _categories[i];
                      final selected =
                          id == 'all' ? filter == null : filter == id;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => ref
                            .read(categoryFilterProvider.notifier)
                            .set(id == 'all' ? null : id),
                        selectedColor:
                            AppColors.accent.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.accent
                              : context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.accent : context.border,
                        ),
                        showCheckmark: false,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  countText,
                  style:
                      TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Tap an exercise for details',
                  style:
                      TextStyle(fontSize: 12, color: context.textTertiary),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final items = ranked ?? list;
                if (items.isEmpty) {
                  return _query.isEmpty
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            'No exercises match "$_query"',
                            style:
                                TextStyle(color: context.textSecondary),
                          ),
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(
                          e.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${e.category[0].toUpperCase()}${e.category.substring(1)} · '
                          '${e.mechanics} · ${e.primaryMuscleId.replaceAll('_', ' ')}'
                          '${e.isCustom ? ' · Custom' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        trailing: e.defaultMetric == 'weight_reps'
                            ? Icon(Icons.fitness_center,
                                size: 18, color: context.textTertiary)
                            : Icon(Icons.timer_outlined,
                                size: 18, color: context.textTertiary),
                        onTap: () => context.push('/library/${e.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
