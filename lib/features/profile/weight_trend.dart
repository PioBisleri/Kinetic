import '../../core/database/database.dart';
import '../../core/utils/day_key.dart';

/// Weight-trend window (Round 6): how far back the Profile chart looks.
const weightTrendWeeks = 12;

/// One weigh-in: local midnight + weight in kg.
class TrendPoint {
  const TrendPoint({required this.day, required this.weightKg});

  final DateTime day;
  final double weightKg;
}

/// Rows → chart points in the last [weightTrendWeeks] weeks of [now],
/// oldest first. Null weights (a malformed row from elsewhere) are
/// skipped rather than plotting at zero.
List<TrendPoint> trendPoints(List<BodyMetric> rows, DateTime now) {
  final from = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: 7 * weightTrendWeeks));
  final points = <TrendPoint>[];
  for (final r in rows) {
    final kg = r.weightKg;
    if (kg == null) continue;
    points.add(TrendPoint(day: parseDayKey(r.id), weightKg: kg));
  }
  points.sort((a, b) => a.day.compareTo(b.day));
  return [for (final p in points) if (!p.day.isBefore(from)) p];
}

/// Mean weight over the [days] days ending at (and including) [day];
/// null when nothing falls in that range.
double? trailingAvg(List<TrendPoint> points, DateTime day, {int days = 7}) {
  final from = DateTime(day.year, day.month, day.day)
      .subtract(Duration(days: days - 1));
  var sum = 0.0;
  var n = 0;
  for (final p in points) {
    if (!p.day.isBefore(from) && !p.day.isAfter(day)) {
      sum += p.weightKg;
      n++;
    }
  }
  return n == 0 ? null : sum / n;
}

/// Last − first over the window (positive = gained); null with fewer
/// than two points.
double? trendDelta(List<TrendPoint> points) =>
    points.length < 2 ? null : points.last.weightKg - points.first.weightKg;
