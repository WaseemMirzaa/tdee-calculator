import 'models/weigh_in.dart';

/// Pure math for the Journey feature — projections, trend smoothing, and the
/// adaptive-TDEE recalibration. No Flutter, no I/O — unit-testable.
class JourneyMath {
  const JourneyMath._();

  static const double kcalPerKgFat = 7700;

  /// Weeks required to move from [currentKg] to [targetKg] given a daily
  /// calorie [dailyDeltaKcal] (negative = deficit for loss, positive = surplus
  /// for gain). Returns null when the delta pushes the wrong direction or is 0.
  static double? weeksToGoal({
    required double currentKg,
    required double targetKg,
    required double dailyDeltaKcal,
  }) {
    final kgToChange = targetKg - currentKg; // negative = need to lose
    if (kgToChange == 0) return 0;
    if (dailyDeltaKcal == 0) return null;
    // Direction must match: losing needs a deficit (negative delta).
    if (kgToChange < 0 && dailyDeltaKcal >= 0) return null;
    if (kgToChange > 0 && dailyDeltaKcal <= 0) return null;

    final kgPerDay = dailyDeltaKcal.abs() / kcalPerKgFat;
    if (kgPerDay == 0) return null;
    final days = kgToChange.abs() / kgPerDay;
    return days / 7;
  }

  /// Projected arrival date from now.
  static DateTime? projectedDate({
    required double currentKg,
    required double targetKg,
    required double dailyDeltaKcal,
    required DateTime from,
  }) {
    final weeks = weeksToGoal(
      currentKg: currentKg,
      targetKg: targetKg,
      dailyDeltaKcal: dailyDeltaKcal,
    );
    if (weeks == null) return null;
    return from.add(Duration(days: (weeks * 7).round()));
  }

  /// The weekly rate (kg/week) implied by a daily calorie delta.
  static double weeklyRateForDelta(double dailyDeltaKcal) =>
      (dailyDeltaKcal.abs() * 7) / kcalPerKgFat;

  /// Exponential moving average of weigh-ins to smooth daily noise. Alpha in
  /// (0,1]; higher = more responsive. Returns one smoothed point per input.
  static List<double> smoothedTrend(List<WeighIn> weighIns, {double alpha = 0.35}) {
    if (weighIns.isEmpty) return const [];
    final out = <double>[];
    double ema = weighIns.first.weightKg;
    for (final w in weighIns) {
      ema = alpha * w.weightKg + (1 - alpha) * ema;
      out.add(ema);
    }
    return out;
  }

  /// Net weight change (kg) between the first and last weigh-in.
  static double? netChangeKg(List<WeighIn> weighIns) {
    if (weighIns.length < 2) return null;
    return weighIns.last.weightKg - weighIns.first.weightKg;
  }

  /// Adaptive (real) maintenance calories, inferred from the user's own data.
  ///
  /// Given the average daily [intakeKcal] the user reported over a window and
  /// the actual [weightChangeKg] across [days], back-solves the maintenance
  /// level the body actually held to. This is what a static calculator cannot
  /// do: it learns the user's true metabolism.
  ///
  ///   realMaintenance = avgIntake − (weightChange · 7700 / days)
  ///
  /// A weight *gain* on a given intake implies maintenance was lower; a loss
  /// implies it was higher.
  static double? adaptiveMaintenance({
    required double intakeKcal,
    required double weightChangeKg,
    required int days,
  }) {
    if (days <= 0) return null;
    final dailyStorageKcal = (weightChangeKg * kcalPerKgFat) / days;
    return intakeKcal - dailyStorageKcal;
  }
}
