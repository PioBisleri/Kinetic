import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/ledger/ledger.dart';
import '../../../core/search/smart_search.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';

/// Carries a pre-fill name from the add-exercise sheet to the exercise
/// editor. Plain global — no schema, no persistence, one-time handoff.
String? exerciseNamePrefill;

/// Searchable exercise picker — returns the exercise id, or null.
Future<String?> showAddExerciseSheet(BuildContext context) {
  return showAppSheet<String>(
    context: context,
    isScrollControlled: true,
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
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x5,
              AppSpace.x3,
              AppSpace.x5,
              AppSpace.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 36, height: 3, color: context.border),
                ),
                const SizedBox(height: AppSpace.x4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add exercise',
                            style: AppType.h1.copyWith(
                              color: context.textPrimary,
                              fontSize: 28,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CATALOG / SEARCH BY NAME, MUSCLE OR TYPO',
                            style: AppType.metaSm.copyWith(
                              color: context.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '01',
                      style: AppType.meta.copyWith(color: context.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x3),
                Rule(),
                const SizedBox(height: AppSpace.x3),
                TextField(
                  key: const Key('exercise-search'),
                  controller: _controller,
                  autofocus: true,
                  onChanged: (v) => setState(() => _search = v),
                  style: AppType.body.copyWith(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search exercises…',
                    hintStyle: AppType.body.copyWith(
                      color: context.textTertiary,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LedgerGlyph(
                        LedgerGlyphType.search,
                        size: 16,
                        color: context.textTertiary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    filled: true,
                    fillColor: context.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: context.accent),
                    ),
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
                final ranked = searchCatalog(
                  list,
                  _search,
                  muscleNames: muscleNames,
                );
                if (ranked.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.x5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No exercises match "$_search"',
                            style: AppType.body.copyWith(
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpace.x4),
                          OutlinedButton.icon(
                            key: const Key('create-exercise'),
                            onPressed: () {
                              exerciseNamePrefill = _search.trim().isEmpty
                                  ? null
                                  : _search.trim();
                              context.pop();
                              context.push('/library/new');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.textPrimary,
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.control,
                                ),
                              ),
                            ),
                            icon: LedgerGlyph(
                              LedgerGlyphType.plus,
                              size: 13,
                              color: context.textPrimary,
                            ),
                            label: Text('Create "${_search.trim()}"'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.x5,
                    0,
                    AppSpace.x5,
                    AppSpace.x6,
                  ),
                  itemCount: ranked.length,
                  itemBuilder: (context, i) {
                    final e = ranked[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(e.id),
                        splashColor: context.accent.withValues(alpha: 0.06),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.x3,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: context.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.name,
                                      style: AppType.body.copyWith(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${e.category} · ${e.mechanics}'
                                          .toUpperCase(),
                                      style: AppType.metaSm.copyWith(
                                        color: context.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.x3),
                              LedgerGlyph(
                                LedgerGlyphType.plus,
                                size: 16,
                                color: context.accent,
                              ),
                            ],
                          ),
                        ),
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
