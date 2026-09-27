/// Local calendar-day keys: one string per day, e.g. `'2026-09-27'`.
///
/// Body-metric rows are keyed by the day they were taken (not the
/// instant), so re-weighing twice today updates one point — on this
/// device and, after sync, on every other.
library;

/// `'2026-09-27'` for the local calendar day of [at].
String dayKey(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')}';

/// Inverse of [dayKey]: local midnight of that day.
DateTime parseDayKey(String key) => DateTime(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
