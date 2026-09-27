import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bmi.dart';
import '../../core/utils/height_units.dart';
import '../../core/utils/weight_units.dart';
import '../../core/widgets/section_card.dart';

/// "Your data" — every personal input in one card (Round 5): name,
/// height, date of birth, sex, body fat %, training goal, bodyweight,
/// and the derived BMI row.
///
/// All fields hydrate from the synced `local` profile row and save
/// independently (partial upsert — each row only touches its own
/// column). Height stores canonical cm and renders as cm or ft/in to
/// match the unit setting; nothing here feeds the grade math.
class YourDataCard extends StatelessWidget {
  const YourDataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Your data',
      children: const [
        _NameField(),
        _HeightField(),
        _DobRow(),
        _SexRow(),
        _BodyFatField(),
        _GoalRow(),
        _BodyweightRow(),
        _BmiRow(),
      ],
    );
  }
}

/// Partial upsert onto the local profile row — provided columns only.
Future<void> _writeProfile(WidgetRef ref, ProfilesCompanion values) =>
    ref.read(databaseProvider).profiles.insertOnConflictUpdate(values);

/// Name shown in exports and backups.
class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  final _controller = TextEditingController();
  bool _dirty = false;
  String? _hydrated;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(String? name) {
    if (_dirty || _hydrated == name) return;
    _hydrated = name;
    final text = name ?? '';
    if (_controller.text != text) _controller.text = text;
  }

  Future<void> _save(String text) async {
    final name = text.trim();
    _dirty = false; // stream emit below writes back the canonical value
    await _writeProfile(
      ref,
      ProfilesCompanion.insert(
        id: 'local',
        updatedAt: DateTime.now(),
        username: Value(name.isEmpty ? null : name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _hydrate(ref.watch(profileProvider).value?.username);
    ref.listen(
        profileProvider, (_, next) => _hydrate(next.value?.username));

    return ListTile(
      dense: true,
      title: const Text('Name'),
      trailing: SizedBox(
        width: 150,
        child: TextField(
          key: const Key('profile-name'),
          controller: _controller,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 14),
          maxLength: 30,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Add',
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: (_) => _dirty = true,
          onSubmitted: _save,
        ),
      ),
    );
  }
}

/// Height — one cm field in metric, ft + in fields in imperial;
/// canonical storage is always cm.
class _HeightField extends ConsumerStatefulWidget {
  const _HeightField();

  @override
  ConsumerState<_HeightField> createState() => _HeightFieldState();
}

class _HeightFieldState extends ConsumerState<_HeightField> {
  final _cm = TextEditingController();
  final _ft = TextEditingController();
  final _in = TextEditingController();
  bool _dirty = false;
  UnitSystem? _shownUnit;
  double? _hydratedCm;

  @override
  void dispose() {
    _cm.dispose();
    _ft.dispose();
    _in.dispose();
    super.dispose();
  }

  void _hydrate(double? cm, UnitSystem unit) {
    if (_dirty || (_shownUnit == unit && _hydratedCm == cm)) return;
    _shownUnit = unit;
    _hydratedCm = cm;
    if (unit == UnitSystem.kg) {
      final text = cm == null ? '' : _trim(cm);
      if (_cm.text != text) _cm.text = text;
    } else if (cm == null) {
      _ft.clear();
      _in.clear();
    } else {
      final fi = cmToFeetInches(cm);
      final ft = fi.feet.toString();
      final inch = fi.inches.toString();
      if (_ft.text != ft) _ft.text = ft;
      if (_in.text != inch) _in.text = inch;
    }
  }

  String _trim(double cm) => cm == cm.roundToDouble()
      ? cm.toStringAsFixed(0)
      : cm.toStringAsFixed(1);

  Future<void> _save(double? cm) async {
    if (!isValidHeightCm(cm)) return; // ignore garbage
    _dirty = false;
    await _writeProfile(
      ref,
      ProfilesCompanion.insert(
        id: 'local',
        updatedAt: DateTime.now(),
        heightCm: Value(cm),
      ),
    );
  }

  Future<void> _saveMetric(String text) =>
      _save(double.tryParse(text.trim().replaceAll(',', '.')));

  Future<void> _saveImperial(String _) async {
    final ft = int.tryParse(_ft.text.trim()) ?? -1;
    final inch = int.tryParse(_in.text.trim()) ?? -1;
    if (ft < 0 || ft > 8 || inch < 0 || inch > 11) return;
    await _save(feetInchesToCm(ft, inch));
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider).unit;
    final heightCm = ref.watch(profileProvider).value?.heightCm;
    if (!_dirty && _shownUnit != unit) _hydrate(heightCm, unit);
    ref.listen(profileProvider,
        (_, next) => _hydrate(next.value?.heightCm, unit));

    const contentPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);
    final digits = [FilteringTextInputFormatter.digitsOnly];

    if (unit == UnitSystem.kg) {
      return ListTile(
        dense: true,
        title: const Text('Height'),
        trailing: SizedBox(
          width: 110,
          child: TextField(
            key: const Key('profile-height'),
            controller: _cm,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            inputFormatters: digits,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Add',
              suffixText: 'cm',
              contentPadding: contentPadding,
            ),
            onChanged: (_) => _dirty = true,
            onSubmitted: _saveMetric,
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      title: const Text('Height'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            child: TextField(
              key: const Key('profile-height'),
              controller: _ft,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              inputFormatters: digits,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '—',
                suffixText: 'ft',
                contentPadding: contentPadding,
              ),
              onChanged: (_) => _dirty = true,
              onSubmitted: _saveImperial,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 64,
            child: TextField(
              key: const Key('profile-height-in'),
              controller: _in,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              inputFormatters: digits,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '—',
                suffixText: 'in',
                contentPadding: contentPadding,
              ),
              onChanged: (_) => _dirty = true,
              onSubmitted: _saveImperial,
            ),
          ),
        ],
      ),
    );
  }
}

/// Date-of-birth picker with the derived age as the subtitle.
class _DobRow extends ConsumerWidget {
  const _DobRow();

  int? _age(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age < 0 || age > 120 ? null : age;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = ref.watch(profileProvider).value?.birthDate;
    final date = iso == null ? null : DateTime.tryParse(iso);
    final age = date == null ? null : _age(date);

    return ListTile(
      key: const Key('profile-dob'),
      dense: true,
      title: const Text('Date of birth'),
      subtitle: date == null
          ? null
          : Text(
              age == null ? '' : '$age years old',
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
      trailing: TextButton(
        key: const Key('profile-dob-pick'),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked == null || !context.mounted) return;
          await _writeProfile(
            ref,
            ProfilesCompanion.insert(
              id: 'local',
              updatedAt: DateTime.now(),
              birthDate: Value(DateFormat('yyyy-MM-dd').format(picked)),
            ),
          );
        },
        child: Text(
          date == null
              ? 'Add'
              : DateFormat('MMM d, yyyy').format(date),
          style: TextStyle(
            fontSize: 13,
            color: date == null ? context.textTertiary : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Sex — stored for the record (and future age/sex-aware stats); the
/// grade math deliberately does not use it yet.
class _SexRow extends ConsumerWidget {
  const _SexRow();

  static const _labels = {
    'female': 'Female',
    'male': 'Male',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sex = ref.watch(profileProvider).value?.sex;
    return ListTile(
      dense: true,
      title: const Text('Sex'),
      trailing: DropdownButton<String>(
        key: const Key('profile-sex'),
        value: _labels.containsKey(sex) ? sex : null,
        underline: const SizedBox.shrink(),
        hint: Text('Add',
            style: TextStyle(fontSize: 14, color: context.textTertiary)),
        style: TextStyle(fontSize: 14, color: context.textPrimary),
        items: [
          for (final e in _labels.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => _writeProfile(
          ref,
          ProfilesCompanion.insert(
            id: 'local',
            updatedAt: DateTime.now(),
            sex: Value(v),
          ),
        ),
      ),
    );
  }
}

/// Body fat percentage (2–60 plausible range).
class _BodyFatField extends ConsumerStatefulWidget {
  const _BodyFatField();

  @override
  ConsumerState<_BodyFatField> createState() => _BodyFatFieldState();
}

class _BodyFatFieldState extends ConsumerState<_BodyFatField> {
  final _controller = TextEditingController();
  bool _dirty = false;
  double? _hydrated;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(double? pct) {
    if (_dirty || _hydrated == pct) return;
    _hydrated = pct;
    final text = pct == null ? '' : _trim(pct);
    if (_controller.text != text) _controller.text = text;
  }

  String _trim(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1);

  Future<void> _save(String text) async {
    final pct = double.tryParse(text.trim().replaceAll(',', '.'));
    if (pct == null || pct < 2 || pct > 60) return; // ignore garbage
    _dirty = false;
    await _writeProfile(
      ref,
      ProfilesCompanion.insert(
        id: 'local',
        updatedAt: DateTime.now(),
        bodyFatPct: Value(pct),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _hydrate(ref.watch(profileProvider).value?.bodyFatPct);
    ref.listen(profileProvider, (_, next) => _hydrate(next.value?.bodyFatPct));

    return ListTile(
      dense: true,
      title: const Text('Body fat'),
      trailing: SizedBox(
        width: 110,
        child: TextField(
          key: const Key('profile-bf'),
          controller: _controller,
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d?)?$')),
          ],
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Add',
            suffixText: '%',
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: (_) => _dirty = true,
          onSubmitted: _save,
        ),
      ),
    );
  }
}

/// Training goal — display-only for now, but the natural anchor for
/// future default targets.
class _GoalRow extends ConsumerWidget {
  const _GoalRow();

  static const _labels = {
    'strength': 'Strength',
    'hypertrophy': 'Hypertrophy',
    'general': 'General fitness',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(profileProvider).value?.trainingGoal;
    return ListTile(
      dense: true,
      title: const Text('Goal'),
      trailing: DropdownButton<String>(
        key: const Key('profile-goal'),
        value: _labels.containsKey(goal) ? goal : null,
        underline: const SizedBox.shrink(),
        hint: Text('Add',
            style: TextStyle(fontSize: 14, color: context.textTertiary)),
        style: TextStyle(fontSize: 14, color: context.textPrimary),
        items: [
          for (final e in _labels.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => _writeProfile(
          ref,
          ProfilesCompanion.insert(
            id: 'local',
            updatedAt: DateTime.now(),
            trainingGoal: Value(v),
          ),
        ),
      ),
    );
  }
}

/// Bodyweight row — moved here from Profile's old "Body" card.
class _BodyweightRow extends StatelessWidget {
  const _BodyweightRow();

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: const Icon(Icons.monitor_weight_outlined, size: 22),
        title: const Text('Bodyweight'),
        subtitle: const Text(
          'Powers Muscle Grade strength scores',
          style: TextStyle(fontSize: 12),
        ),
        trailing: SizedBox(width: 110, child: const _BodyweightField()),
      );
}

/// Bodyweight input, shown in display units and stored in kg on the local
/// profile row. Hydration follows the profile stream until the user edits.
class _BodyweightField extends ConsumerStatefulWidget {
  const _BodyweightField();

  @override
  ConsumerState<_BodyweightField> createState() => _BodyweightFieldState();
}

class _BodyweightFieldState extends ConsumerState<_BodyweightField> {
  final _controller = TextEditingController();
  UnitSystem? _shownUnit;
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(double? kg, UnitSystem unit) {
    if (_dirty) return;
    _shownUnit = unit;
    final text = kg == null ? '' : formatWeight(kg, unit);
    if (_controller.text != text) _controller.text = text;
  }

  Future<void> _save(String text, UnitSystem unit) async {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 400) return; // ignore garbage
    final kg = displayToKg(value, unit);
    _dirty = false; // stream emit below writes back the canonical display
    await _writeProfile(
      ref,
      ProfilesCompanion.insert(
        id: 'local',
        updatedAt: DateTime.now(),
        bodyweightKg: Value(kg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider).unit;
    final kg = ref.watch(profileProvider).value?.bodyweightKg;

    // First build or a unit toggle → reformat from the stored kg.
    if (!_dirty && _shownUnit != unit) _hydrate(kg, unit);
    // Profile rows arriving later (or our own save) → keep text canonical.
    ref.listen(
      profileProvider,
      (prev, next) => _hydrate(next.value?.bodyweightKg, unit),
    );

    return TextField(
      key: const Key('bodyweight-input'),
      controller: _controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?$')),
      ],
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixText: unit == UnitSystem.lbs ? 'lb' : 'kg',
        suffixStyle:
            TextStyle(fontSize: 12, color: context.textTertiary),
      ),
      onChanged: (_) => _dirty = true,
      onSubmitted: (text) => _save(text, unit),
    );
  }
}

/// Derived BMI row — hidden behind nothing: it always renders, hinting
/// what it needs, so the feature is discoverable.
class _BmiRow extends ConsumerWidget {
  const _BmiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final bmi = bmiFor(
      heightCm: profile?.heightCm,
      weightKg: profile?.bodyweightKg,
    );

    return ListTile(
      key: const Key('profile-bmi'),
      dense: true,
      title: const Text('BMI'),
      trailing: bmi == null
          ? Text(
              'Add height + weight',
              style:
                  TextStyle(fontSize: 13, color: context.textTertiary),
            )
          : Text(
              '${bmi.toStringAsFixed(1)} · ${bmiLabel(bmiCategory(bmi))}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
              ),
            ),
    );
  }
}
