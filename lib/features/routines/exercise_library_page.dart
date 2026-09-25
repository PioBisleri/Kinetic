import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
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
class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final filter = ref.watch(categoryFilterProvider);
    final count = ref.watch(exerciseCountProvider);

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
                  switch (count) {
                    AsyncData(:final value) => '$value exercises',
                    _ => 'Loading…',
                  },
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
              data: (list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = list[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text(
                        e.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
