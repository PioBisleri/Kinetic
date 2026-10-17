import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import '../../core/widgets/app_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/search/smart_search.dart';
import '../../core/theme/app_theme.dart';
import '../health/health_providers.dart';
import '../health/live_activity_service.dart';
import 'application/nutrition_providers.dart';

String _fmt(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// Ranked food picker (tap a row = log one serving). Same ranking engine
/// as the exercise sheet, generic over the row type.
class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({super.key});

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(foodLibraryProvider);
    final day = ref.watch(todayKeyProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('diet-food-search'),
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search my foods…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          Flexible(
            child: libraryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              data: (foods) {
                final ranked = rankMatches<Food>(
                  _query,
                  foods,
                  name: (f) => f.name,
                  muscle: (f) => f.brand ?? '',
                  category: (f) => f.servingUnit,
                );
                final tip = _controller.text.trim();
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    ...[
                      for (final food in ranked)
                        ListTile(
                          key: Key('diet-pick-${food.id}'),
                          dense: true,
                          title: Text(
                            food.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${food.kcal.round()} kcal · '
                            '${_fmt(food.servingSize)} ${food.servingUnit}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.textSecondary,
                            ),
                          ),
                          onTap: () {
                            final repo = ref.read(foodRepositoryProvider);
                            unawaited(
                              repo.logFood(
                                dayKey: day,
                                food: food,
                                servings: 1,
                              ),
                            );
                            // The live notification's kcal target surface
                            // reads today's log — push a fresh snapshot.
                            ref.read(liveActivityControllerProvider).refresh();
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('diet-pick-create'),
                      dense: true,
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(
                        tip.isEmpty
                            ? 'Create a new food'
                            : 'Create "$tip"',
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        unawaited(
                          showFoodEditorSheet(context, initialName: tip),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('diet-pick-manual'),
                      dense: true,
                      leading: const Icon(Icons.edit_note_outlined),
                      title: const Text('Log without saving (macros only)'),
                      onTap: () {
                        Navigator.of(context).pop();
                        unawaited(showManualLogSheet(context));
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Create/edit food form (per-serving macros, per-100 g default).
Future<void> showFoodEditorSheet(
  BuildContext context, {
  Food? food,
  String? initialName,
}) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FoodEditorSheet(food: food, initialName: initialName),
    );

class _FoodEditorSheet extends ConsumerStatefulWidget {
  const _FoodEditorSheet({this.food, this.initialName});

  final Food? food;
  final String? initialName;

  @override
  ConsumerState<_FoodEditorSheet> createState() => _FoodEditorSheetState();
}

class _FoodEditorSheetState extends ConsumerState<_FoodEditorSheet> {
  late final TextEditingController _name;
  final _brand = TextEditingController();
  final _serving = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _servingUnit = 'g';
  String? _nameError;

  static const _units = ['g', 'ml', 'piece'];

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _name = TextEditingController(text: f?.name ?? widget.initialName ?? '');
    _brand.text = f?.brand ?? '';
    _serving.text = _fmt(f?.servingSize ?? 100);
    _servingUnit = f?.servingUnit ?? 'g';
    _kcal.text = _fmt(f?.kcal ?? 0);
    _protein.text = _fmt(f?.proteinG ?? 0);
    _carbs.text = _fmt(f?.carbsG ?? 0);
    _fat.text = _fmt(f?.fatG ?? 0);
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _serving.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double _numOr(TextEditingController c, double fallback) =>
      _num(c) ?? fallback;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    final serving = _num(_serving);
    if (serving == null || serving <= 0) {
      setState(() => _nameError = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Serving size must be a number > 0')),
      );
      return;
    }
    final repo = ref.read(foodRepositoryProvider);
    try {
      await repo.saveFood(
        id: widget.food?.id,
        name: name,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        servingSize: serving,
        servingUnit: _servingUnit,
        kcal: _numOr(_kcal, 0),
        proteinG: _numOr(_protein, 0),
        carbsG: _numOr(_carbs, 0),
        fatG: _numOr(_fat, 0),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Food save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.food == null ? 'New food' : 'Edit food',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Macros are per serving.',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('diet-food-name'),
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('diet-food-serving'),
                    controller: _serving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Serving size',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _servingUnit,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final u in _units)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (u) =>
                      setState(() => _servingUnit = u ?? _servingUnit),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _numField('kcal', _kcal),
                const SizedBox(width: 10),
                _numField('Protein g', _protein),
                const SizedBox(width: 10),
                _numField('Carbs g', _carbs),
                const SizedBox(width: 10),
                _numField('Fat g', _fat),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('diet-food-save'),
              onPressed: () => unawaited(_save()),
              child: const Text('Save food'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) =>
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}

/// Quick manual macros entry — no library row. Stored kcal comes from the
/// Atwater formula so daily totals stay internally consistent.
Future<void> showManualLogSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ManualLogSheet(),
    );

class _ManualLogSheet extends ConsumerStatefulWidget {
  const _ManualLogSheet();

  @override
  ConsumerState<_ManualLogSheet> createState() => _ManualLogSheetState();
}

class _ManualLogSheetState extends ConsumerState<_ManualLogSheet> {
  final _name = TextEditingController();
  final _servings = TextEditingController(text: '1');
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Give the entry a name')),
      );
      return;
    }
    final repo = ref.read(foodRepositoryProvider);
    final day = ref.read(todayKeyProvider);
    try {
      await repo.logManual(
        dayKey: day,
        name: name,
        servings: double.tryParse(
                _servings.text.trim().replaceAll(',', '.')) ??
            1,
        proteinG: _double(_protein),
        carbsG: _double(_carbs),
        fatG: _double(_fat),
      );
      ref.read(liveActivityControllerProvider).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Manual log failed: $e');
    }
  }

  double _double(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final kcalPreview = (double.tryParse(
                  _protein.text.trim().replaceAll(',', '.')) ??
              0) *
          4 +
        (double.tryParse(_carbs.text.trim().replaceAll(',', '.')) ?? 0) * 4 +
        (double.tryParse(_fat.text.trim().replaceAll(',', '.')) ?? 0) * 9;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log macros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved only for today — no library entry is created.',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('diet-manual-name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _servings,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Servings',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _field('Protein g', _protein),
                const SizedBox(width: 10),
                _field('Carbs g', _carbs),
                const SizedBox(width: 10),
                _field('Fat g', _fat),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '≈ ${kcalPreview.round()} kcal',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('diet-manual-save'),
              onPressed: () => unawaited(_log()),
              child: const Text('Log it'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => Expanded(
        child: TextField(
          key: Key('diet-manual-${label.toLowerCase().replaceAll(' ', '-')}'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}
