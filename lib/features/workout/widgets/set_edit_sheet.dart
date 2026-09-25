import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_units.dart';
import 'plate_bar.dart';

/// What the editor hands back — the caller decides how to persist.
class SetDraft {
  SetDraft({
    this.weightKg,
    this.reps,
    this.rpe,
    this.setType = 'working',
    this.distanceM,
    this.durationSec,
    this.heartRate,
  });

  double? weightKg;
  int? reps;
  double? rpe;
  String setType;
  double? distanceM;
  int? durationSec;
  int? heartRate;

  bool get isEmptyValues =>
      weightKg == null &&
      reps == null &&
      rpe == null &&
      distanceM == null &&
      durationSec == null;
}

const _setTypes = [
  ('warmup', 'Warm-up'),
  ('working', 'Working'),
  ('drop', 'Drop'),
  ('failure', 'Failure'),
];

/// Opens the big-target set editor.
/// Returns the edited [SetDraft], the string 'delete', or null on cancel.
Future<Object?> showSetEditSheet(
  BuildContext context, {
  required Exercise exercise,
  SetDraft? initial,
  int? setNumber,
}) {
  return showModalBottomSheet<SetDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      // Keep fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SetEditSheet(
        exercise: exercise,
        initial: initial,
        setNumber: setNumber,
      ),
    ),
  );
}

class SetEditSheet extends ConsumerStatefulWidget {
  const SetEditSheet({
    super.key,
    required this.exercise,
    this.initial,
    this.setNumber,
  });

  final Exercise exercise;
  final SetDraft? initial;
  final int? setNumber;

  @override
  ConsumerState<SetEditSheet> createState() => _SetEditSheetState();
}

class _SetEditSheetState extends ConsumerState<SetEditSheet> {
  late final SetDraft _draft;
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _distance;
  late final TextEditingController _durationMin;
  late final TextEditingController _rpe;
  bool _hasExisting = false;

  bool get _isCardio => widget.exercise.defaultMetric != 'weight_reps';

  @override
  void initState() {
    super.initState();
    final unit = ref.read(settingsProvider).unit;
    final i = widget.initial;
    _hasExisting = i != null && widget.setNumber != null;
    _draft = SetDraft(
      weightKg: i?.weightKg,
      reps: i?.reps,
      rpe: i?.rpe,
      setType: i?.setType ?? 'working',
      distanceM: i?.distanceM,
      durationSec: i?.durationSec,
      heartRate: i?.heartRate,
    );
    _weight = TextEditingController(
      text: i?.weightKg != null ? formatWeight(i!.weightKg!, unit) : '',
    );
    _reps = TextEditingController(
      text: i?.reps?.toString() ?? '',
    );
    _distance = TextEditingController(
      text: i?.distanceM != null ? i!.distanceM!.round().toString() : '',
    );
    _durationMin = TextEditingController(
      text: i?.durationSec != null
          ? (i!.durationSec! / 60).toStringAsFixed(1)
          : '',
    );
    _rpe = TextEditingController(
      text: i?.rpe != null ? _fmtRpe(i!.rpe!) : '',
    );
  }

  static String _fmtRpe(double r) => r == r.roundToDouble()
      ? r.toStringAsFixed(0)
      : r.toStringAsFixed(1);

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _distance.dispose();
    _durationMin.dispose();
    _rpe.dispose();
    super.dispose();
  }

  void _bumpWeight(double direction) {
    final unit = ref.read(settingsProvider).unit;
    final current = _parseWeight();
    final next =
        (current ?? 0) + direction * stepKg(unit);
    final clamped = next < 0 ? 0.0 : next;
    setState(() {
      _draft.weightKg = clamped;
      _weight.text = formatWeight(clamped, unit);
    });
  }

  void _bumpReps(int direction) {
    final current = int.tryParse(_reps.text.trim()) ?? 0;
    final next = (current + direction).clamp(0, 999);
    setState(() {
      _draft.reps = next;
      _reps.text = next.toString();
    });
  }

  double? _parseWeight() {
    final unit = ref.read(settingsProvider).unit;
    final raw = _weight.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;
    return displayToKg(value, unit);
  }

  int? _parseReps() => int.tryParse(_reps.text.trim());

  void _save() {
    final draft = SetDraft(
      weightKg: _isCardio ? null : _parseWeight(),
      reps: _isCardio ? null : _parseReps(),
      rpe: _isCardio
          ? null
          : double.tryParse(_rpe.text.trim().replaceAll(',', '.')),
      setType: _draft.setType,
      distanceM: _isCardio
          ? double.tryParse(_distance.text.trim())
          : null,
      durationSec: _isCardio
          ? ((double.tryParse(_durationMin.text.trim()) ?? 0) * 60).round()
          : null,
      heartRate: _draft.heartRate,
    );
    if (draft.isEmptyValues && !_isCardio) {
      Navigator.of(context).pop(); // nothing entered → treat as cancel
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider).unit;
    final plateMetric = ref.watch(settingsProvider).plateSetMetric;
    final weightLabel = unit == UnitSystem.kg ? 'kg' : 'lb';
    final title = widget.setNumber != null
        ? 'Set ${widget.setNumber}'
        : 'New set';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          Text(
            widget.exercise.name,
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 16),

          if (!_isCardio) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final (id, label) in _setTypes)
                  ChoiceChip(
                    label: Text(label),
                    selected: _draft.setType == id,
                    onSelected: (_) =>
                        setState(() => _draft.setType = id),
                    showCheckmark: false,
                    selectedColor: AppColors.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _draft.setType == id
                          ? AppColors.accent
                          : context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _draft.setType == id
                          ? AppColors.accent
                          : context.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _StepperRow(
              label: 'Weight',
              unit: weightLabel,
              controller: _weight,
              fieldKey: const Key('set-weight-input'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onMinus: () => _bumpWeight(-1),
              onPlus: () => _bumpWeight(1),
              onChanged: () => setState(() => _draft.weightKg = _parseWeight()),
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: 'Reps',
              controller: _reps,
              fieldKey: const Key('set-reps-input'),
              keyboardType: TextInputType.number,
              onMinus: () => _bumpReps(-1),
              onPlus: () => _bumpReps(1),
              onChanged: () => setState(() => _draft.reps = _parseReps()),
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: 'RPE',
              hint: 'optional',
              controller: _rpe,
              fieldKey: const Key('set-rpe-input'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onMinus: () {},
              onPlus: () {},
              onChanged: () {},
            ),
            const SizedBox(height: 12),
            PlateBar(
              totalKg: _draft.weightKg ?? 0,
              metric: plateMetric,
            ),
          ] else ...[
            _StepperRow(
              label: 'Distance',
              unit: 'm',
              controller: _distance,
              fieldKey: const Key('set-distance-input'),
              keyboardType: TextInputType.number,
              onMinus: () {},
              onPlus: () {},
              onChanged: () {},
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: 'Duration',
              unit: 'min',
              controller: _durationMin,
              fieldKey: const Key('set-duration-input'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onMinus: () {},
              onPlus: () {},
              onChanged: () {},
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              if (_hasExisting)
                TextButton(
                  onPressed: () => Navigator.of(context).pop('delete'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.heatHot),
                  child: const Text('Delete'),
                ),
              const Spacer(),
              Expanded(
                child: FilledButton(
                  key: const Key('set-save'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.keyboardType,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
    this.unit,
    this.hint,
  });

  final String label;
  final String? unit;
  final String? hint;
  final TextEditingController controller;
  final Key fieldKey;
  final TextInputType keyboardType;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${hint != null ? ' · $hint' : ''}',
          style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _roundButton(context, Icons.remove, onMinus),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: fieldKey,
                controller: controller,
                onChanged: (_) => onChanged(),
                keyboardType: keyboardType,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()]),
                decoration: InputDecoration(
                  hintText: '—',
                  suffixText: unit,
                  suffixStyle:
                      TextStyle(fontSize: 14, color: context.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _roundButton(context, Icons.add, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _roundButton(BuildContext context, IconData icon, VoidCallback onTap) =>
      IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: context.surfaceElevated,
          foregroundColor: context.textPrimary,
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: context.border)),
        ),
        icon: Icon(icon, size: 26),
      );
}
