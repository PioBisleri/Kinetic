import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/ledger/ledger.dart';
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
      CategoryFilterNotifier.new,
    );

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
      AsyncData(:final value) => searchCatalog(
        value,
        _query,
        muscleNames: muscleNames,
      ),
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
      appBar: const TailBar(title: 'Exercise Library', showMenu: false),
      floatingActionButton: FloatingActionButton(
        key: const Key('create-exercise'),
        tooltip: 'New exercise',
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: context.accent,
        foregroundColor: onAccent(context.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onPressed: () => context.push('/library/new'),
        child: LedgerGlyph(
          LedgerGlyphType.plus,
          color: onAccent(context.accent),
          size: 20,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x5,
                AppSpace.x2,
                AppSpace.x5,
                0,
              ),
              child: _SearchBox(
                controller: _searchCtrl,
                query: _query,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            _CategoryRail(filter: filter),
            const SizedBox(height: AppSpace.x5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x5),
              child: SectionHead(
                index: '01',
                title: 'Catalog',
                meta: countText,
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5,
                  0,
                  AppSpace.x5,
                  AppSpace.x5,
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppRadius.data),
                    border: Border.all(color: context.border),
                  ),
                  child: exercises.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.x4),
                        child: Text(
                          'Error: $e',
                          textAlign: TextAlign.center,
                          style: AppType.bodySm.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    data: (list) {
                      final items = ranked ?? list;
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpace.x4),
                            child: Text(
                              _query.isEmpty
                                  ? 'No exercises yet.'
                                  : 'No exercises match "$_query"',
                              textAlign: TextAlign.center,
                              style: AppType.bodySm.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Rule(),
                        itemBuilder: (context, i) => _ExerciseRow(
                          exercise: items[i],
                          onTap: () => context.push('/library/${items[i].id}'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.data),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          LedgerGlyph(
            LedgerGlyphType.search,
            size: 17,
            color: context.textTertiary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              key: const Key('library-search'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppType.bodySm.copyWith(color: context.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Find a movement',
                hintStyle: AppType.bodySm.copyWith(color: context.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (query.isNotEmpty)
            SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                key: const Key('library-search-clear'),
                tooltip: 'Clear search',
                padding: EdgeInsets.zero,
                onPressed: onClear,
                icon: LedgerGlyph(
                  LedgerGlyphType.close,
                  size: 15,
                  color: context.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRail extends ConsumerWidget {
  const _CategoryRail({required this.filter});

  final String? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.x5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.data),
        border: Border.all(color: context.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _categories.length; i++) ...[
              if (i > 0) Container(width: 1, color: context.border),
              Builder(
                builder: (context) {
                  final (id, label) = _categories[i];
                  final selected = id == 'all' ? filter == null : filter == id;
                  return _CategoryTab(
                    label: label,
                    selected: selected,
                    onTap: () => ref
                        .read(categoryFilterProvider.notifier)
                        .set(id == 'all' ? null : id),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: context.accent.withValues(alpha: 0.06),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? context.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppType.bodySm.copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? context.accent : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category =
        '${exercise.category[0].toUpperCase()}${exercise.category.substring(1)}';
    final meta =
        '$category · ${exercise.mechanics} · '
        '${exercise.primaryMuscleId.replaceAll('_', ' ')}'
        '${exercise.isCustom ? ' · Custom' : ''}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: context.accent.withValues(alpha: 0.05),
        highlightColor: context.accent.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                exercise.defaultMetric == 'weight_reps' ? 'LOAD' : 'TIME',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
              const SizedBox(width: 8),
              LedgerGlyph(
                LedgerGlyphType.chevronRight,
                size: 15,
                color: context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
