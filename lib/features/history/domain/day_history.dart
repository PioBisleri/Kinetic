import '../../../core/database/database.dart';
import '../../nutrition/domain/food_math.dart';

/// Energy math for the History page (Round 10) — pure, no I/O.
///
/// [kStepMeters] and [kKcalPerKgKm] are the Kotlin `KineticLiveService`
/// constants `STEP_M`/`KCAL_PER_KG_KM` (meters per step, kcal per kg per
/// km; meters → km via ÷1000). Both sides MUST stay in step: the live
/// notification and this page show the same walking number for the same
/// day. [kLiftingMet] is the moderate-lifting MET applied to the whole
/// session time (rest between sets included) — retune here to retune
/// every burn estimate.
const double kStepMeters = 0.762;
const double kKcalPerKgKm = 1.036;
const double kLiftingMet = 4.5;

/// Walking energy: bodyweight × distance(km) × 1.036. Zero when the step
/// count or bodyweight is missing — nothing is invented.
double walkingKcal(int steps, double weightKg) =>
    weightKg * (steps * kStepMeters / 1000.0) * kKcalPerKgKm;

/// Session energy for one workout: MET × bodyweight × hours.
double workoutBurnKcal(int durationSec, double weightKg) =>
    kLiftingMet * weightKg * durationSec / 3600.0;

/// One finished workout with its day-level aggregates (counted once per
/// [dayHistoryProvider] fetch) — everything the History page shows in a
/// workout row without touching the database again.
final class DayWorkout {
  const DayWorkout({
    required this.workout,
    required this.routineName,
    required this.setCount,
    required this.cardioSec,
    required this.kcalBurn,
  });

  final Workout workout;
  final String routineName; // routine name, or 'Workout' (deleted/none)
  final int setCount; // completed sets, same semantics as Home's tile
  final int cardioSec; // completed cardio rows' duration (informational)
  final double kcalBurn; // 0 when no bodyweight is known for the day
}

/// Everything one calendar day records: body metrics, food logs and
/// finished workout sessions, assembled by [dayHistoryProvider].
final class DayHistory {
  const DayHistory({
    required this.dayKey,
    this.weightKg,
    this.prevWeightKg,
    this.prevWeightDay,
    this.steps,
    this.waterMl,
    this.foodLogs = const [],
    this.totals = MacroTotals.zero,
    this.workouts = const [],
  });

  final String dayKey;

  /// This day's weigh-in (null when none was taken).
  final double? weightKg;

  /// Latest weigh-in strictly before this day — delta for today's value,
  /// and the fallback display when this day has no weigh-in.
  final double? prevWeightKg;

  /// [prevWeightKg]'s day key (its row id) for "last weigh-in on …" copy.
  final String? prevWeightDay;

  /// This day's step count (null when the sensor never reported).
  final int? steps;

  /// This day's hydration total in ml (null when never touched).
  final int? waterMl;

  /// Food log rows for the day, newest first.
  final List<FoodLog> foodLogs;

  /// Sum of [foodLogs].
  final MacroTotals totals;

  /// Finished sessions that started this local day, newest first.
  final List<DayWorkout> workouts;

  /// Bodyweight feeding the calorie estimates: this day's weigh-in when
  /// present, else the latest prior one. Null = no estimate anywhere.
  double? get burnWeightKg => weightKg ?? prevWeightKg;

  /// Walking kcal for the day — null without a step count or a known
  /// bodyweight (the formula needs both inputs; nothing is invented).
  double? get walkingBurn => (steps == null || burnWeightKg == null)
      ? null
      : walkingKcal(steps!, burnWeightKg!);

  /// Session kcal summed over the day's finished workouts.
  double get workoutBurn =>
      workouts.fold(0, (a, w) => a + w.kcalBurn);

  /// Walking + workouts — what this day burned beyond resting metabolism.
  double? get totalBurned =>
      burnWeightKg == null ? null : (walkingBurn ?? 0) + workoutBurn;

  /// Intake minus burn (positive = surplus).
  double? get netKcal =>
      totalBurned == null ? null : totals.kcal - totalBurned!;

  /// True when the day itself carries no recorded value — the All tab
  /// shows the empty state instead of a dashboard of zeroes. Prior days'
  /// weigh-ins ([prevWeightKg]) don't count: they aren't this day's data.
  bool get isEmpty =>
      weightKg == null &&
      steps == null &&
      waterMl == null &&
      foodLogs.isEmpty &&
      workouts.isEmpty;
}
