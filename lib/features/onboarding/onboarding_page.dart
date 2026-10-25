import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/height_units.dart';
import '../../core/utils/weight_units.dart';
import '../health/step_tracker.dart';
import '../profile/body_metric_log.dart';
import 'onboarding_gate.dart';

const _goalLabels = {
  'strength': ('Strength', 'Low reps · heavy work'),
  'hypertrophy': ('Hypertrophy', 'Volume · muscle size'),
  'general': ('General fitness', 'Move well · stay consistent'),
};

/// First-run setup: a three-pane ledger that lands the user on Home with a
/// local profile and their display units already chosen.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _lastStep = 2;

  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _heightCm = TextEditingController();
  final _heightFt = TextEditingController();
  final _heightIn = TextEditingController();

  late UnitSystem _unit;
  int _step = 0;
  String? _goal;
  String? _error;
  bool _saving = false;

  bool get _metric => _unit == UnitSystem.kg;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(settingsProvider).unit;
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _heightCm.dispose();
    _heightFt.dispose();
    _heightIn.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < _lastStep) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    _finish();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) return;
    setState(() {
      _step--;
      _error = null;
    });
  }

  void _setUnit(UnitSystem next) {
    if (next == _unit) return;
    final oldUnit = _unit;

    final weightText = _weight.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(weightText);
    final weightKg = weight == null ? null : displayToKg(weight, oldUnit);
    final heightCm = _readHeightCm(oldUnit);

    setState(() {
      _unit = next;
      _error = null;
    });

    if (weightKg != null) _weight.text = formatWeight(weightKg, next);
    if (heightCm != null) _writeHeight(heightCm);
  }

  double? _readHeightCm(UnitSystem unit) {
    if (unit == UnitSystem.kg) {
      return double.tryParse(_heightCm.text.trim().replaceAll(',', '.'));
    }
    final ft = int.tryParse(_heightFt.text.trim());
    final inches = int.tryParse(_heightIn.text.trim());
    if (ft == null || inches == null) return null;
    return feetInchesToCm(ft, inches);
  }

  void _writeHeight(double cm) {
    if (_metric) {
      _heightCm.text = _trim(cm);
      return;
    }
    final fi = cmToFeetInches(cm);
    _heightFt.text = fi.feet.toString();
    _heightIn.text = fi.inches.toString();
  }

  String _trim(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : _trim2(value);

  String _trim2(double value) =>
      value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  ({double? kg, String? error}) _weightValue() {
    final text = _weight.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return (kg: null, error: null);
    final value = double.tryParse(text);
    if (value == null || value <= 0 || value > 400) {
      return (
        kg: null,
        error: 'Enter a bodyweight between 1 and 400 ${unitLabel(_unit)}.',
      );
    }
    return (kg: displayToKg(value, _unit), error: null);
  }

  ({double? cm, String? error}) _heightValue() {
    if (_metric) {
      final text = _heightCm.text.trim().replaceAll(',', '.');
      if (text.isEmpty) return (cm: null, error: null);
      final cm = double.tryParse(text);
      if (cm == null || cm < 100 || cm > 250) {
        return (cm: null, error: 'Enter a height between 100 and 250 cm.');
      }
      return (cm: cm, error: null);
    }

    final ftText = _heightFt.text.trim();
    final inText = _heightIn.text.trim();
    if (ftText.isEmpty && inText.isEmpty) return (cm: null, error: null);
    final ft = int.tryParse(ftText);
    final inches = int.tryParse(inText);
    if (ft == null ||
        inches == null ||
        ft < 3 ||
        ft > 8 ||
        inches < 0 ||
        inches > 11) {
      return (cm: null, error: 'Enter a height between 3 and 8 ft.');
    }
    final cm = feetInchesToCm(ft, inches);
    if (cm < 100 || cm > 250) {
      return (cm: null, error: 'Enter a height between 100 and 250 cm.');
    }
    return (cm: cm, error: null);
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    final weight = _weightValue();
    if (weight.error != null) {
      setState(() => _error = weight.error);
      return;
    }
    final height = _heightValue();
    if (height.error != null) {
      setState(() => _error = height.error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final name = _name.text.trim();
      final db = ref.read(databaseProvider);
      final now = DateTime.now().toUtc();
      final hasProfile =
          name.isNotEmpty ||
          _goal != null ||
          weight.kg != null ||
          height.cm != null;

      if (hasProfile) {
        await db
            .into(db.profiles)
            .insertOnConflictUpdate(
              ProfilesCompanion.insert(
                id: 'local',
                updatedAt: now,
                username: Value(name.isEmpty ? null : name),
                trainingGoal: Value(_goal),
                bodyweightKg: Value(weight.kg),
                heightCm: Value(height.cm),
              ),
            );
      }

      if (weight.kg != null) await logBodyWeight(db, weight.kg!);
      await _complete();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save your setup. Try again.';
      });
    }
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    await _complete();
  }

  Future<void> _complete() async {
    await ref.read(settingsProvider.notifier).setUnit(_unit);
    await ref.read(sharedPreferencesProvider).setBool(onboardingDoneKey, true);
    try {
      unawaited(ref.read(stepTrackerProvider).start());
    } catch (_) {
      // No platform channel in widget tests; startup stays best-effort.
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _back();
      },
      child: Scaffold(
        key: const Key('onboarding-page'),
        backgroundColor: context.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(step: _step, saving: _saving, onSkip: _skip),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('onboarding-step-$_step'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.x5,
                    AppSpace.x4,
                    AppSpace.x5,
                    AppSpace.x6,
                  ),
                  child: switch (_step) {
                    0 => const _WelcomeStep(),
                    1 => _ProfileStep(
                      name: _name,
                      goal: _goal,
                      unit: _unit,
                      onGoal: (goal) => setState(() => _goal = goal),
                      onUnit: _setUnit,
                    ),
                    _ => _BaselineStep(
                      unit: _unit,
                      weight: _weight,
                      heightCm: _heightCm,
                      heightFt: _heightFt,
                      heightIn: _heightIn,
                    ),
                  },
                ),
              ),
              _Footer(
                step: _step,
                saving: _saving,
                error: _error,
                onBack: _back,
                onNext: _next,
                onSkip: _skip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.saving,
    required this.onSkip,
  });

  final int step;
  final bool saving;
  final VoidCallback onSkip;

  static const _labels = ['WELCOME', 'PROFILE', 'BASELINE'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.x5,
        AppSpace.x3,
        AppSpace.x5,
        0,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KINETIC',
                      style: AppType.h1.copyWith(
                        fontSize: 21,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'PRIVATE TRAINING LEDGER',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.metaSm.copyWith(
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (step > 0)
                TextButton(
                  key: const Key('onboarding-skip'),
                  onPressed: saving ? null : onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: context.textTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'SKIP',
                    style: AppType.metaSm.copyWith(color: context.textTertiary),
                  ),
                ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '0${step + 1} / 03',
                  style: AppType.meta.copyWith(color: context.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x3),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    height: 2,
                    color: i <= step ? context.accent : context.border,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _labels[step],
              style: AppType.meta.copyWith(color: context.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your training,\non the record.',
          style: AppType.h1.copyWith(fontSize: 38, height: 0.98),
        ),
        const SizedBox(height: AppSpace.x4),
        Text(
          'A private training log with no account, no feed and no cloud. '
          'Open it, lift, and keep the receipts.',
          style: AppType.body.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpace.x5),
        LedgerPanel(
          index: '01',
          title: 'The rules',
          meta: 'local-first',
          padding: EdgeInsets.zero,
          child: Column(
            children: const [
              _PromiseRow(
                index: '01',
                title: 'No account',
                body: 'There is nothing to sign up for.',
              ),
              Rule(),
              _PromiseRow(
                index: '02',
                title: 'No cloud',
                body: 'Your log stays on this device by default.',
              ),
              Rule(),
              _PromiseRow(
                index: '03',
                title: 'No feed',
                body: 'Only your records, not anyone else’s.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x4),
        Align(
          alignment: Alignment.centerLeft,
          child: Stamp('Yours to keep', color: context.textTertiary),
        ),
      ],
    );
  }
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.body.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppType.bodySm.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.name,
    required this.goal,
    required this.unit,
    required this.onGoal,
    required this.onUnit,
  });

  final TextEditingController name;
  final String? goal;
  final UnitSystem unit;
  final ValueChanged<String> onGoal;
  final ValueChanged<UnitSystem> onUnit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Who’s training?', style: AppType.h1.copyWith(fontSize: 34)),
        const SizedBox(height: AppSpace.x2),
        Text(
          'A name for your exports and backups. You can leave it blank.',
          style: AppType.body.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpace.x5),
        const SectionHead(index: '01', title: 'Name', meta: 'optional'),
        const SizedBox(height: AppSpace.x3),
        TextField(
          key: const Key('onboarding-name'),
          controller: name,
          maxLength: 30,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: AppType.body.copyWith(color: context.textPrimary),
          decoration: _fieldDecoration(
            context,
            hint: 'What should the ledger call you?',
          ),
        ),
        const SizedBox(height: AppSpace.x5),
        SectionHead(
          index: '02',
          title: 'Training goal',
          meta: goal == null ? 'optional' : 'selected',
        ),
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final entry in _goalLabels.entries)
                _ChoiceRow(
                  key: Key('onboarding-goal-${entry.key}'),
                  title: entry.value.$1,
                  subtitle: entry.value.$2,
                  selected: goal == entry.key,
                  onTap: () => onGoal(entry.key),
                  divider: entry.key != _goalLabels.keys.last,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x5),
        const SectionHead(index: '03', title: 'Units', meta: 'display'),
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: _UnitCell(
                  key: const Key('onboarding-unit-kg'),
                  label: 'KG',
                  sub: 'Metric',
                  selected: unit == UnitSystem.kg,
                  onTap: () => onUnit(UnitSystem.kg),
                ),
              ),
              Container(width: 1, height: 52, color: context.border),
              Expanded(
                child: _UnitCell(
                  key: const Key('onboarding-unit-lbs'),
                  label: 'LB',
                  sub: 'Imperial',
                  selected: unit == UnitSystem.lbs,
                  onTap: () => onUnit(UnitSystem.lbs),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x4),
        Text(
          'You can change all of this later in Profile and Settings.',
          style: AppType.bodySm.copyWith(color: context.textTertiary),
        ),
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.divider,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: context.accent.withValues(alpha: 0.06),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: divider
                  ? Border(bottom: BorderSide(color: context.border))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Row(
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? context.accent : context.textTertiary,
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? Container(width: 7, height: 7, color: context.accent)
                        : null,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppType.body.copyWith(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle.toUpperCase(),
                          style: AppType.metaSm.copyWith(
                            color: context.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitCell extends StatelessWidget {
  const _UnitCell({
    super.key,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: context.accent.withValues(alpha: 0.06),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        color: selected
            ? context.accent.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.meta.copyWith(
                color: selected ? context.accent : context.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub.toUpperCase(),
              style: AppType.metaSm.copyWith(color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaselineStep extends StatelessWidget {
  const _BaselineStep({
    required this.unit,
    required this.weight,
    required this.heightCm,
    required this.heightFt,
    required this.heightIn,
  });

  final UnitSystem unit;
  final TextEditingController weight;
  final TextEditingController heightCm;
  final TextEditingController heightFt;
  final TextEditingController heightIn;

  @override
  Widget build(BuildContext context) {
    final metric = unit == UnitSystem.kg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Set your baseline.', style: AppType.h1.copyWith(fontSize: 34)),
        const SizedBox(height: AppSpace.x2),
        Text(
          'Optional, but it makes Muscle Grade and BMI useful from day one.',
          style: AppType.body.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpace.x5),
        const SectionHead(index: '04', title: 'Body', meta: 'optional'),
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _BodyInputRow(
                title: 'Bodyweight',
                subtitle: 'Powers Muscle Grade',
                control: SizedBox(
                  width: 96,
                  child: _NumberField(
                    key: const Key('onboarding-weight'),
                    controller: weight,
                    suffix: unitLabel(unit),
                    decimal: true,
                    action: TextInputAction.next,
                  ),
                ),
              ),
              Rule(),
              if (metric)
                _BodyInputRow(
                  title: 'Height',
                  subtitle: 'Used for BMI',
                  control: SizedBox(
                    width: 96,
                    child: _NumberField(
                      key: const Key('onboarding-height'),
                      controller: heightCm,
                      suffix: 'cm',
                      decimal: true,
                      action: TextInputAction.done,
                    ),
                  ),
                )
              else
                _BodyInputRow(
                  title: 'Height',
                  subtitle: 'Used for BMI',
                  control: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 62,
                        child: _NumberField(
                          key: const Key('onboarding-height-ft'),
                          controller: heightFt,
                          suffix: 'ft',
                          action: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 62,
                        child: _NumberField(
                          key: const Key('onboarding-height-in'),
                          controller: heightIn,
                          suffix: 'in',
                          action: TextInputAction.done,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: context.border),
            borderRadius: BorderRadius.circular(AppRadius.data),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 5),
                color: context.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Private by default. Export a JSON backup any time from '
                  'Settings → Data.',
                  style: AppType.bodySm.copyWith(color: context.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyInputRow extends StatelessWidget {
  const _BodyInputRow({
    required this.title,
    required this.subtitle,
    required this.control,
  });

  final String title;
  final String subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.body.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toUpperCase(),
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.suffix,
    required this.action,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String suffix;
  final TextInputAction action;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: action,
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?$'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: AppType.data.copyWith(color: context.textPrimary),
      decoration: _fieldDecoration(
        context,
        hint: '—',
        suffix: suffix,
      ).copyWith(contentPadding: const EdgeInsets.fromLTRB(8, 9, 8, 9)),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  String? hint,
  String? suffix,
}) => InputDecoration(
  hintText: hint,
  suffixText: suffix,
  hintStyle: AppType.body.copyWith(color: context.textTertiary),
  suffixStyle: AppType.metaSm.copyWith(color: context.textTertiary),
  filled: true,
  fillColor: context.surfaceElevated,
  counterText: '',
  contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
);

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.saving,
    required this.error,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final bool saving;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = switch (step) {
      0 => 'Begin setup',
      1 => 'Continue',
      _ => 'Start training',
    };
    return Container(
      decoration: BoxDecoration(
        color: context.background,
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.x5,
        AppSpace.x3,
        AppSpace.x5,
        AppSpace.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Text(error!, style: AppType.bodySm.copyWith(color: context.danger)),
            const SizedBox(height: AppSpace.x2),
          ],
          Row(
            children: [
              if (step > 0) ...[
                TextButton(
                  key: const Key('onboarding-back'),
                  onPressed: saving ? null : onBack,
                  style: TextButton.styleFrom(
                    foregroundColor: context.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('BACK'),
                ),
                const SizedBox(width: AppSpace.x3),
              ],
              Expanded(
                child: PushKey(
                  key: const Key('onboarding-next'),
                  label: saving ? 'Saving…' : primaryLabel,
                  height: 50,
                  enabled: !saving,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
          if (step == 0) ...[
            const SizedBox(height: AppSpace.x1),
            TextButton(
              key: const Key('onboarding-skip-setup'),
              onPressed: saving ? null : onSkip,
              style: TextButton.styleFrom(
                foregroundColor: context.textTertiary,
                minimumSize: const Size.fromHeight(38),
              ),
              child: Text(
                'SKIP FOR NOW',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
