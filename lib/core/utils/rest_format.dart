/// Formats a rest duration for compact display.
///
/// `0` (or less) → `'Off'`, `45` → `'45s'`, `90` → `'1m 30s'`, `120` → `'2m'`.
String formatRest(int seconds) {
  if (seconds <= 0) return 'Off';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '${s}s';
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}
