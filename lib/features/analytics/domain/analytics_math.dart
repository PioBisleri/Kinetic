/// Pure date/aggregation math for the Analytics tab.
///
/// No Flutter or Drift imports — trivially unit-testable. All dates are
/// local-time calendar days; arithmetic goes through [addDays] (day-unit
/// constructor math) so DST transitions can never shift a bucket.
library;

/// Set types that count as real training volume — warm-ups and cardio are
/// excluded. Shared by the live session and the analytics rollups so the
/// total on Home always adds up to the totals on Analytics.
const hardSetTypes = {'working', 'drop', 'failure'};

/// One Monday-start week of accumulated volume (kg).
class WeekPoint {
  const WeekPoint(this.weekStart, this.volumeKg);

  final DateTime weekStart;
  final double volumeKg;
}

/// Midnight of the calendar day containing [t].
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// [d] shifted by [n] calendar days (DST-proof day arithmetic).
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Monday 00:00 of the week containing [t].
DateTime weekStartOf(DateTime t) {
  final d = dayOf(t);
  return addDays(d, 1 - d.weekday); // DateTime.monday == 1
}

/// Whole calendar days from [a] to [b] (b − a), timezone-safe.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

/// First day covered by a [weeks]-long window ending in the week of [now]:
/// exactly [weeks] Monday-start slots, aligned with [bucketWeekly].
/// [weeks] == 0 means "All" → the epoch (every real log is newer).
DateTime periodStart(int weeks, DateTime now) => weeks <= 0
    ? DateTime(1970)
    : addDays(weekStartOf(now), -7 * (weeks - 1));

/// Where a chart's x-axis begins: the Monday slot for bounded periods,
/// the earliest data point for "All" (weeks == 0) — plotting from the
/// epoch would cram every bar into the far right of the axis.
/// Falls back to [periodStart] when [dates] is empty.
DateTime chartStart(int weeks, DateTime now, Iterable<DateTime> dates) {
  if (weeks > 0) return periodStart(weeks, now);
  DateTime? earliest;
  for (final d in dates) {
    if (earliest == null || d.isBefore(earliest)) earliest = d;
  }
  return earliest ?? periodStart(weeks, now);
}

/// Buckets day-level volumes into [weeks] Monday-start weeks ending with
/// the week containing [now]. Empty weeks are present with 0 kg; days
/// outside the window are dropped. [weeks] <= 0 ("All") sizes the window
/// from the data itself — one slot when there is none.
List<WeekPoint> bucketWeekly(
  Iterable<({DateTime date, double volumeKg})> days, {
  required DateTime now,
  required int weeks,
}) {
  final totals = <DateTime, double>{};
  for (final d in days) {
    final ws = weekStartOf(d.date);
    totals[ws] = (totals[ws] ?? 0) + d.volumeKg;
  }

  final thisWeek = weekStartOf(now);
  var slots = weeks;
  if (slots <= 0) {
    slots = 1;
    for (final ws in totals.keys) {
      if (ws.isBefore(thisWeek)) {
        final n = daysBetween(ws, thisWeek) ~/ 7 + 1;
        if (n > slots) slots = n;
      }
    }
  }

  final out = <WeekPoint>[];
  for (var i = slots - 1; i >= 0; i--) {
    final ws = addDays(thisWeek, -7 * i);
    out.add(WeekPoint(ws, totals[ws] ?? 0));
  }
  return out;
}

/// Consecutive weeks (Mon–Sun) containing at least one workout, counting
/// back from the week of [now]. The unfinished current week gets grace: if
/// it has no workout yet, the streak starts from last week instead of
/// breaking.
int weeklyStreak(Iterable<DateTime> workoutDates, {required DateTime now}) {
  final trained = <DateTime>{for (final d in workoutDates) weekStartOf(d)};
  final thisWeek = weekStartOf(now);
  var cursor = trained.contains(thisWeek) ? thisWeek : addDays(thisWeek, -7);
  var streak = 0;
  while (trained.contains(cursor)) {
    streak++;
    cursor = addDays(cursor, -7);
  }
  return streak;
}

/// Compact stat/axis number: `625`, `1.1k`, `12.4k`, `105k`.
String compactNumber(double v) {
  final a = v.abs();
  if (a >= 100000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.round().toString();
}
