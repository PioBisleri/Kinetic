import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/search/smart_search.dart';
import '../../../core/theme/app_theme.dart';

/// Searchable exercise picker — returns the exercise id, or null.
Future<String?> showAddExerciseSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
    ),
    builder: (_) => const AddExerciseSheet(),
  );
}

class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _controller = TextEditingController();

  /// Local per-open search: no provider round-trip, no stale filter.
  String _search = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One subscription for the whole sheet: the family arg no longer
    // changes per keystroke, so typing never resubscribes (and never
    // flashes a spinner) — ranking is per-keystroke and client-side
    // (typos, synonyms, muscle matches — SQL LIKE can't).
    final exercises = ref.watch(dbExercisesProvider((category: null)));
    final muscleNames = ref.watch(muscleNamesProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add exercise',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('exercise-search'),
                  controller: _controller,
                  autofocus: false,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search exercises…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final ranked = searchCatalog(list, _search,
                    muscleNames: muscleNames);
                if (ranked.isEmpty) {
                  return Center(
                    child: Text(
                      'No exercises match "$_search"',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: ranked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final e = ranked[i];
                    return Card(
                      child: ListTile(
                        title: Text(e.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${e.category} · ${e.mechanics}',
                          style: TextStyle(
                              fontSize: 12, color: context.textSecondary),
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.of(context).pop(e.id),
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
