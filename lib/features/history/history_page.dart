import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bmi.dart';
import '../../core/utils/day_key.dart';
import '../../core/utils/weight_units.dart';
import '../../core/widgets/app_empty.dart';
import '../../core/widgets/section_card.dart';
import '../analytics/domain/analytics_math.dart' show compactNumber;
import '../nutrition/domain/food_math.dart';
import 'domain/day_history.dart';
import 'history_providers.dart';

/// `/history` (Round 10) — the day browser: one page, six sub-tabs
/// (All · Workouts · Steps · Food · Water · Burned) over a date selector.
/// Pick any day, see everything the app recorded for it; Today stays live
/// while the page is open. Read-only by design — logging happens on Diet
/// and the workout logger, this page only presents.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with SingleTickerProviderStateMixin {
  static const _tabLabels = [
    'All',
    'Workouts',
    'Steps',
    'Food',
    'Water',
    'Burned',
  ];
  static const _tabKeys = ['all', 'workouts', 'steps', 'food', 'water', 'burned'];

  late final TabController _tab;
  late String _dayKey;
  final _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _dayKey = dayKey(DateTime.now());
    _tab = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _setDay(String key) {
    if (key == _dayKey) return;
    setState(() => _dayKey = key);
    // Bring the selected chip into view (it can sit outside the strip).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[key]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.4,
        );
      }
    });
  }

  Future<void> _pickDate() async {
    final initial = parseDayKey(_dayKey);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
    );
    if (picked != null && mounted) _setDay(dayKey(picked));
  }

  /// Chip strip: the days from the selected day up to today; when the
  /// selection is older than the last 30, its chip is pinned first so it
  /// is always reachable without hunting.
  List<String> _chipDays() {
    final now = parseDayKey(dayKey(DateTime.now()));
    final sel = parseDayKey(_dayKey);
    if (sel.isAfter(now)) return [dayKey(now)];
    final span = now.difference(sel).inDays;
    final out = <String>[];
    if (span >= 30) out.add(_dayKey);
    final count = span >= 30 ? 29 : span;
    for (var i = count; i >= 0; i--) {
      out.add(dayKey(now.subtract(Duration(days: i))));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final today = dayKey(DateTime.now());
    final isToday = _dayKey == today;
    final history = ref.watch(dayHistoryProvider(_dayKey));
    final week = ref.watch(weekBodyMetricsProvider(_dayKey)).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _dateBar(isToday),
            _chipStrip(),
            TabBar(
              controller: _tab,
              isScrollable: true,
              tabs: [
                for (var i = 0; i < _tabKeys.length; i++)
                  Tab(key: Key('history-tab-${_tabKeys[i]}'), text: _tabLabels[i]),
              ],
            ),
            Expanded(
              child: history.when(
                loading: () => const Center(
                  key: Key('history-loading'),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    EmptyState(
                      message: 'Could not load this day.',
                      secondary: 'Go back to today and try again.',
                    ),
                  ],
                ),
                data: (h) => TabBarView(
                  controller: _tab,
                  children: [
                    _allTab(day: h, week: week),
                    _workoutsTab(day: h),
                    _stepsTab(day: h, week: week),
                    _foodTab(day: h),
                    _waterTab(day: h, week: week),
                    _burnedTab(day: h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBar(bool isToday) {
    final parsed = parseDayKey(_dayKey);
    final now = DateTime.now();
    final today = parseDayKey(dayKey(now));
    final diff = today.difference(parsed).inDays;
    final sub = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : diff > 1
                ? '$diff days ago'
                : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('history-prev-day'),
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _setDay(
              dayKey(parsed.subtract(const Duration(days: 1))),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  key: const Key('history-date-label'),
                  DateFormat('EEE, d MMM yyyy').format(parsed),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(
                        fontSize: 11, color: context.textTertiary),
                  ),
              ],
            ),
          ),
          if (!isToday)
            TextButton(
              key: const Key('history-today-jump'),
              onPressed: () => _setDay(dayKey(now)),
              child: const Text('Today'),
            ),
          IconButton(
            key: const Key('history-date-picker'),
            tooltip: 'Pick a date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  Widget _chipStrip() {
    final days = _chipDays();
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final k = days[i];
          final selected = k == _dayKey;
          final key = _chipKeys.putIfAbsent(k, GlobalKey.new);
          final d = parseDayKey(k);
          final ink = selected ? onAccent(context.accent) : null;
          return Container(
            key: key,
            child: Material(
              color: selected ? context.accent : context.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: Key('history-date-$k'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _setDay(k),
                child: SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E().format(d),
                        style: TextStyle(
                          fontSize: 10,
                          color: ink ?? context.textTertiary,
                        ),
                      ),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ink ?? context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- sparkline feed: 7 values ending on the selected day ----

  List<double> _weekValues(
    List<BodyMetric>? rows,
    int Function(BodyMetric) pick,
  ) {
    if (rows == null) return const [];
    final byDay = {for (final r in rows) r.id: r};
    final end = parseDayKey(_dayKey);
    final out = <double>[];
    for (var i = 6; i >= 0; i--) {
      final r = byDay[dayKey(end.subtract(Duration(days: i)))];
      out.add((r == null ? 0 : pick(r)).toDouble());
    }
    return out;
  }

  double? _weekAvg(List<BodyMetric>? rows, int Function(BodyMetric) pick) {
    if (rows == null || rows.isEmpty) return null;
    var sum = 0;
    var n = 0;
    for (final r in rows) {
      final v = pick(r);
      if (v > 0) {
        sum += v;
        n++;
      }
    }
    return n == 0 ? null : sum / n;
  }

  // ---- tab bodies ----

  Widget _allTab({required DayHistory day, required List<BodyMetric>? week}) {
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider).value;
    final unit = settings.unit;

    if (day.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            message:
                'Nothing recorded on ${DateFormat('EEEE, d MMM').format(parseDayKey(day.dayKey))}.',
            secondary: 'Log a workout, food or water — it shows up here.',
          ),
        ],
      );
    }

    final stepsCard = _MetricCard(
      title: 'STEPS',
      icon: Icons.directions_walk_rounded,
      valueText: day.steps == null ? '—' : '${day.steps}',
      targetText: '/ ${settings.stepsTarget}',
      progress: day.steps == null
          ? 0
          : progress(day.steps!.toDouble(), settings.stepsTarget.toDouble()),
      footnote: day.walkingBurn == null
          ? null
          : '≈ ${day.walkingBurn!.round()} kcal walking',
      avgText: _avgLabel(_weekAvg(week, (r) => r.steps ?? 0), 'steps'),
      spark: _weekValues(week, (r) => r.steps ?? 0),
    );

    final waterCard = _MetricCard(
      title: 'WATER',
      icon: Icons.water_drop_outlined,
      valueText: day.waterMl == null ? '—' : '${day.waterMl}',
      targetText: '/ ${settings.waterTargetMl} ml',
      progress: day.waterMl == null
          ? 0
          : progress(day.waterMl!.toDouble(),
              settings.waterTargetMl.toDouble()),
      avgText: _avgLabel(_weekAvg(week, (r) => r.waterMl ?? 0), 'ml'),
      spark: _weekValues(week, (r) => r.waterMl ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        stepsCard,
        const SizedBox(height: 12),
        waterCard,
        const SizedBox(height: 12),
        _BurnCard(day: day),
        const SizedBox(height: 12),
        _IntakeNetCard(day: day, settings: settings),
        const SizedBox(height: 12),
        _WeighInCard(day: day, heightCm: profile?.heightCm, unit: unit),
        if (day.workouts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WorkoutStrip(day: day, unit: unit),
        ],
      ],
    );
  }

  Widget _workoutsTab({required DayHistory day}) {
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;
    if (day.workouts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            message: 'No workout finished on this day.',
            secondary: 'Sessions you complete on the logger appear here.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SectionCard(
          title: 'FINISHED SESSIONS',
          icon: Icons.fitness_center_rounded,
          children: [
            for (final w in day.workouts)
              ListTile(
                key: Key('history-workout-${w.workout.id}'),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: context.accentDim,
                  child: Icon(Icons.fitness_center_rounded,
                      size: 18, color: context.accent),
                ),
                title: Text(
                  w.routineName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${DateFormat.Hm().format(w.workout.startedAt)} · '
                  '${_duration(w.workout.durationSec)} · '
                  '${w.setCount} sets · '
                  '${compactNumber(kgToDisplay(w.workout.totalVolume, unit))} '
                  '${unitLabel(unit)}'
                  '${day.burnWeightKg == null ? '' : '\n≈ ${w.kcalBurn.round()} kcal burn'}',
                  style: TextStyle(
                      fontSize: 12, color: context.textTertiary, height: 1.4),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () =>
                    context.push('/workout-history/${w.workout.id}'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepsTab({required DayHistory day, required List<BodyMetric>? week}) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _MetricCard(
          title: 'STEPS',
          icon: Icons.directions_walk_rounded,
          valueText: day.steps == null ? '—' : '${day.steps}',
          targetText: '/ ${settings.stepsTarget}',
          progress: day.steps == null
              ? 0
              : progress(
                  day.steps!.toDouble(), settings.stepsTarget.toDouble()),
          footnote: day.walkingBurn == null
              ? (day.steps == null ? null : 'add a weigh-in for kcal')
              : '≈ ${day.walkingBurn!.round()} kcal walking',
          avgText: _avgLabel(_weekAvg(week, (r) => r.steps ?? 0), 'steps'),
          spark: _weekValues(week, (r) => r.steps ?? 0),
          sparkWidth: double.infinity,
          sparkHeight: 48,
        ),
        if (day.steps == null) ...[
          const SizedBox(height: 12),
          Text(
            'The pedometer never reported on this day.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ],
      ],
    );
  }

  Widget _foodTab({required DayHistory day}) {
    final settings = ref.watch(settingsProvider);
    final t = day.totals;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SectionCard(
          title: 'INTAKE',
          icon: Icons.restaurant_outlined,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        key: const Key('history-food-kcal'),
                        '${t.kcal.round()}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '/ ${settings.kcalTarget} kcal',
                          style: TextStyle(
                              fontSize: 13, color: context.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress(t.kcal, settings.kcalTarget.toDouble()),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: context.surfaceElevated,
                    color: context.accent,
                  ),
                ],
              ),
            ),
            if (day.foodLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Nothing logged on this day.',
                  style:
                      TextStyle(fontSize: 13, color: context.textTertiary),
                ),
              ),
            for (final log in day.foodLogs)
              ListTile(
                dense: true,
                key: Key('history-food-${log.id}'),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    DateFormat.Hm().format(log.loggedAt),
                    style: TextStyle(
                        fontSize: 12, color: context.textTertiary),
                  ),
                ),
                title: Text(
                  log.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${_servings(log.servings)} · '
                  'P ${log.proteinG.round()} · '
                  'C ${log.carbsG.round()} · '
                  'F ${log.fatG.round()}',
                  style:
                      TextStyle(fontSize: 12, color: context.textTertiary),
                ),
                trailing: Text(
                  '${log.kcal.round()} kcal',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'MACROS',
          icon: Icons.donut_small_outlined,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  _macroCell('Protein', t.proteinG, settings.proteinTargetG),
                  _macroCell('Carbs', t.carbsG, settings.carbsTargetG),
                  _macroCell('Fat', t.fatG, settings.fatTargetG),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _macroCell(String label, double done, int target) => Expanded(
        child: Column(
          children: [
            Text(
              '${done.round()} / $target',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '$label g',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      );

  Widget _waterTab({required DayHistory day, required List<BodyMetric>? week}) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _MetricCard(
          title: 'WATER',
          icon: Icons.water_drop_outlined,
          valueText: day.waterMl == null ? '—' : '${day.waterMl}',
          targetText: '/ ${settings.waterTargetMl} ml',
          progress: day.waterMl == null
              ? 0
              : progress(day.waterMl!.toDouble(),
                  settings.waterTargetMl.toDouble()),
          avgText: _avgLabel(_weekAvg(week, (r) => r.waterMl ?? 0), 'ml'),
          spark: _weekValues(week, (r) => r.waterMl ?? 0),
          sparkWidth: double.infinity,
          sparkHeight: 48,
        ),
      ],
    );
  }

  Widget _burnedTab({required DayHistory day}) {
    final settings = ref.watch(settingsProvider);
    final noWeight = day.burnWeightKg == null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SectionCard(
          title: 'CALORIES BURNED',
          icon: Icons.local_fire_department_outlined,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  _HistoryKvRow('Walking',
                      noWeight ? null : day.walkingBurn?.round().toString()),
                  _HistoryKvRow('Workout',
                      noWeight ? null : day.workoutBurn.round().toString()),
                  Divider(height: 20, color: context.border),
                  _HistoryKvRow(
                    'Total',
                    noWeight ? null : day.totalBurned?.round().toString(),
                    valueColor: context.accent,
                    fontSize: 17,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                noWeight
                    ? 'Add a weigh-in to estimate calories burned.'
                    : 'walking: bodyweight × km × 1.036 · '
                        'workout: MET $kLiftingMet × bodyweight × hours',
                style: TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'INTAKE & NET',
          icon: Icons.restaurant_outlined,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _HistoryKvRow('Intake', '${day.totals.kcal.round()}'),
                  _HistoryKvRow('Burned',
                      noWeight ? null : day.totalBurned?.round().toString()),
                  Divider(height: 20, color: context.border),
                  _HistoryKvRow(
                    'Net',
                    noWeight ? null : _signed(day.netKcal),
                    valueColor: context.accent,
                    fontSize: 17,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'intake target ${settings.kcalTarget} kcal · '
                'positive net = surplus',
                style: TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- shared pieces ----

  static String _signed(double? v) =>
      v == null ? '—' : '${v >= 0 ? '+' : '−'}${v.abs().round()}';

  static String _duration(int? sec) {
    final minutes = (sec ?? 0) ~/ 60;
    return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
  }

  static String _servings(double servings) {
    final whole = servings.roundToDouble() == servings;
    final n = whole ? servings.round().toString() : servings.toStringAsFixed(1);
    return '$n×';
  }

  static String? _avgLabel(double? avg, String unit) =>
      avg == null ? null : '7-day avg ${avg.round()} $unit';
}

/// One metric block (Steps / Water): headline vs target, progress bar,
/// footnote row and a 7-day sparkline — the History page's workhorse.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.valueText,
    required this.targetText,
    required this.progress,
    required this.spark,
    this.footnote,
    this.avgText,
    this.sparkWidth = 120,
    this.sparkHeight = 30,
  });

  final String title;
  final IconData icon;
  final String valueText;
  final String targetText;
  final double progress;
  final String? footnote;
  final String? avgText;
  final List<double> spark;
  final double sparkWidth;
  final double sparkHeight;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueText,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      targetText,
                      style: TextStyle(
                          fontSize: 13, color: context.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: context.surfaceElevated,
                color: context.accent,
              ),
              if (footnote != null || avgText != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (footnote != null)
                      Text(
                        footnote!,
                        style: TextStyle(
                            fontSize: 11, color: context.accent),
                      ),
                    const Spacer(),
                    if (avgText != null)
                      Text(
                        avgText!,
                        style: TextStyle(
                            fontSize: 11, color: context.textTertiary),
                      ),
                  ],
                ),
              ],
              if (spark.length >= 2) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: sparkWidth,
                    height: sparkHeight,
                    child: _Sparkline(values: spark),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Burns card on the All tab — Walking + Workout = Total with footnote.
class _BurnCard extends StatelessWidget {
  const _BurnCard({required this.day});

  final DayHistory day;

  @override
  Widget build(BuildContext context) {
    final noWeight = day.burnWeightKg == null;
    return SectionCard(
      title: 'CALORIES BURNED',
      icon: Icons.local_fire_department_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              _HistoryKvRow(
                'Walking',
                noWeight ? null : day.walkingBurn?.round().toString(),
              ),
              if (day.workouts.isNotEmpty)
                _HistoryKvRow(
                  'Workout',
                  noWeight ? null : day.workoutBurn.round().toString(),
                ),
              Divider(height: 18, color: context.border),
              _HistoryKvRow(
                'Total',
                noWeight ? null : day.totalBurned?.round().toString(),
                valueColor: context.accent,
                fontSize: 17,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            noWeight
                ? 'Add a weigh-in to estimate calories burned.'
                : 'walking: bodyweight × km × 1.036 · '
                    'workout: MET $kLiftingMet × bodyweight × hours',
            style: TextStyle(fontSize: 11, color: context.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _HistoryKvRow extends StatelessWidget {
  const _HistoryKvRow(
    this.label,
    this.value, {
    this.valueColor,
    this.fontSize = 14,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value ?? '—',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Intake vs burn vs net on the All tab — three headline numbers.
class _IntakeNetCard extends StatelessWidget {
  const _IntakeNetCard({required this.day, required this.settings});

  final DayHistory day;
  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    final noWeight = day.burnWeightKg == null;
    Widget cell(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style:
                    TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ],
          ),
        );
    return SectionCard(
      title: 'INTAKE & NET',
      icon: Icons.restaurant_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              cell('Intake', '${day.totals.kcal.round()}'),
              cell(
                'Burned',
                noWeight ? '—' : '${day.totalBurned!.round()}',
              ),
              cell(
                'Net',
                noWeight
                    ? '—'
                    : '${day.netKcal! >= 0 ? '+' : '−'}${day.netKcal!.abs().round()}',
                color: noWeight ? null : context.accent,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'kcal · target ${settings.kcalTarget} · positive net = surplus',
            style: TextStyle(fontSize: 11, color: context.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// Weigh-in on the All tab: this day's value + BMI + delta, or the last
/// known weigh-in when this day has none.
class _WeighInCard extends StatelessWidget {
  const _WeighInCard({
    required this.day,
    required this.heightCm,
    required this.unit,
  });

  final DayHistory day;
  final double? heightCm;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (day.weightKg != null) {
      final bmi = bmiFor(heightCm: heightCm, weightKg: day.weightKg);
      final delta = day.weightKg! - (day.prevWeightKg ?? day.weightKg!);
      final hasDelta = day.prevWeightKg != null;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                key: const Key('history-weight'),
                kgToDisplay(day.weightKg!, unit).toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unitLabel(unit),
                  style: TextStyle(
                      fontSize: 13, color: context.textTertiary),
                ),
              ),
              const Spacer(),
              if (bmi != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'BMI ${bmi.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      bmiLabel(bmiCategory(bmi)),
                      style: TextStyle(
                          fontSize: 11, color: context.textTertiary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasDelta
                ? '${delta >= 0 ? '▲' : '▼'} '
                    '${kgToDisplay(delta.abs(), unit).toStringAsFixed(1)} '
                    '${unitLabel(unit)} since ${DateFormat('d MMM').format(parseDayKey(day.prevWeightDay!))}'
                : 'first weigh-in',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ],
      );
    } else if (day.prevWeightKg != null) {
      body = Text(
        'Last weigh-in: '
        '${kgToDisplay(day.prevWeightKg!, unit).toStringAsFixed(1)} '
        '${unitLabel(unit)} · '
        '${DateFormat('d MMM').format(parseDayKey(day.prevWeightDay!))}',
        style: TextStyle(fontSize: 13, color: context.textSecondary),
      );
    } else {
      body = Text(
        'No weigh-in yet.',
        style: TextStyle(fontSize: 13, color: context.textTertiary),
      );
    }
    return SectionCard(
      title: 'WEIGH-IN',
      icon: Icons.monitor_weight_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: body,
        ),
      ],
    );
  }
}

/// Horizontal strip of the day's workout summary cards (All tab) — tap
/// through to the workout detail viewer.
class _WorkoutStrip extends StatelessWidget {
  const _WorkoutStrip({required this.day, required this.unit});

  final DayHistory day;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'WORKOUTS',
      icon: Icons.fitness_center_rounded,
      children: [
        SizedBox(
          // Title + two-line summary + burn line with breathing room
          // (104 overflowed by 7px on the tallest subtitle).
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            itemCount: day.workouts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final w = day.workouts[i];
              return Material(
                color: context.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: Key('history-workout-card-${w.workout.id}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      context.push('/workout-history/${w.workout.id}'),
                  child: Container(
                    width: 196,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.routineName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_HistoryPageState._duration(w.workout.durationSec)}'
                          ' · ${w.setCount} sets · '
                          '${compactNumber(kgToDisplay(w.workout.totalVolume, unit))} '
                          '${unitLabel(unit)}',
                          style: TextStyle(
                              fontSize: 11.5, color: context.textTertiary),
                        ),
                        const Spacer(),
                        if (day.burnWeightKg != null)
                          Text(
                            '≈ ${w.kcalBurn.round()} kcal burn',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.accent),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 7-day line sparkline — accent stroke, soft area fill, end dot. Values
/// are oldest → newest; fewer than two points render nothing.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparkPainter(
        values: values,
        color: context.accent,
        track: context.border,
      ),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.color,
    required this.track,
  });

  final List<double> values;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
    final peak = values.fold<double>(0, (a, v) => v > a ? v : a);
    final pad = 3.0;
    final w = size.width;
    final h = size.height - pad * 2;

    // Baseline track for empty scales — a flat line reads "nothing
    // recorded" instead of a random spike at zero.
    if (peak <= 0) {
      final y = size.height - pad;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..color = track
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1 ? w / 2 : i * (w / (values.length - 1)),
          size.height - pad - (values[i] / peak) * h,
        ),
    ];

    final fill = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color ||
      old.track != track ||
      !listEquals(old.values, values);
}
