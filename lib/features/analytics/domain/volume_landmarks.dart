/// Weekly volume landmarks (Round 6): the MEV/MAV/MRV "how much is
/// enough" bands drawn on the Analytics card.
///
/// Convention (Israetel/RP-style ranges, tuned for a general lifter):
///   MEV — minimum effective volume: below this, growth is unlikely.
///   MAV — maximum adaptive volume: top of the productive sweet spot.
///   MRV — maximum recoverable volume: beyond this, recovery lags.
///
/// The `volume_landmarks` table stores *overrides only* — a muscle with
/// no row falls back to [landmarkDefaults], so a fresh install renders
/// the whole card without a seed pass or migration backfill.
class Landmark {
  const Landmark({required this.mev, required this.mav, required this.mrv});

  /// Minimum effective sets per week.
  final int mev;

  /// Maximum adaptive sets per week.
  final int mav;

  /// Maximum recoverable sets per week.
  final int mrv;

  /// The edit sheet's save rule: whole sets, strictly ascending, and
  /// small enough to fit the band labels.
  bool get isValid => mev >= 1 && mev < mav && mav < mrv && mrv <= 99;
}

/// Where a weekly dose sits on the band. The card colours the marker
/// (and dims the segment past it) from this.
enum LandmarkZone {
  /// Below MEV — under-stimulating.
  belowMev,

  /// MEV..MAV — the productive sweet spot.
  productive,

  /// MAV..MRV — still viable, diminishing returns.
  aboveMav,

  /// Past MRV — recovery debt.
  aboveMrv,
}

/// Curated defaults: hard sets per week for every gradeable muscle.
/// Order here is display order (matches the muscle catalog).
const landmarkDefaults = <String, Landmark>{
  'chest': Landmark(mev: 8, mav: 18, mrv: 22),
  'upper_chest': Landmark(mev: 4, mav: 10, mrv: 14),
  'lats': Landmark(mev: 8, mav: 16, mrv: 22),
  'traps': Landmark(mev: 6, mav: 14, mrv: 18),
  'rhomboids': Landmark(mev: 4, mav: 10, mrv: 14),
  'spinal_erectors': Landmark(mev: 4, mav: 10, mrv: 14),
  'front_delts': Landmark(mev: 4, mav: 10, mrv: 14),
  'side_delts': Landmark(mev: 6, mav: 16, mrv: 20),
  'rear_delts': Landmark(mev: 4, mav: 12, mrv: 16),
  'biceps': Landmark(mev: 6, mav: 14, mrv: 20),
  'triceps': Landmark(mev: 6, mav: 14, mrv: 20),
  'forearms': Landmark(mev: 4, mav: 10, mrv: 14),
  'abs': Landmark(mev: 4, mav: 10, mrv: 14),
  'obliques': Landmark(mev: 3, mav: 8, mrv: 12),
  'quads': Landmark(mev: 8, mav: 16, mrv: 22),
  'hamstrings': Landmark(mev: 6, mav: 14, mrv: 20),
  'glutes': Landmark(mev: 6, mav: 16, mrv: 20),
  'calves': Landmark(mev: 6, mav: 12, mrv: 16),
};

/// The track runs to 1.25 × MRV so doses past the ceiling stay plottable
/// instead of pinning the marker to the edge.
double landmarkScaleEnd(Landmark lm) => lm.mrv * 1.25;

/// Marker position for [sets] on the0..1 track (clamped at both ends).
double markerFraction(int sets, Landmark lm) {
  final end = landmarkScaleEnd(lm);
  if (end <= 0) return 0;
  return (sets / end).clamp(0.0, 1.0);
}

/// (MEV, MAV, MRV) as fractions of the track, for segment widths.
(double, double, double) landmarkFractions(Landmark lm) {
  final end = landmarkScaleEnd(lm);
  return (lm.mev / end, lm.mav / end, lm.mrv / end);
}

/// Zone classification of a weekly dose. Boundaries are inclusive at the
/// landmark itself: hitting MEV is productive, sitting at MRV is still
/// recoverable, only exceeding it is over.
LandmarkZone landmarkZone(int sets, Landmark lm) {
  if (sets < lm.mev) return LandmarkZone.belowMev;
  if (sets <= lm.mav) return LandmarkZone.productive;
  if (sets <= lm.mrv) return LandmarkZone.aboveMav;
  return LandmarkZone.aboveMrv;
}
