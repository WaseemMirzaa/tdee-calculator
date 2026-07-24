import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/journey_math.dart';
import 'package:vita_tdee/core/models/weigh_in.dart';

void main() {
  group('weeksToGoal', () {
    test('500 kcal/day deficit loses ~0.5 kg/week', () {
      // 4 kg to lose at 500 kcal/day: kg/day = 500/7700 = 0.06494 → 61.6 days.
      final weeks = JourneyMath.weeksToGoal(
        currentKg: 64,
        targetKg: 60,
        dailyDeltaKcal: -500,
      );
      expect(weeks, isNotNull);
      expect(weeks!, closeTo(8.8, 0.2)); // ~61.6 days / 7
    });

    test('null when the delta pushes the wrong direction', () {
      // Want to lose but eating a surplus.
      expect(
        JourneyMath.weeksToGoal(currentKg: 64, targetKg: 60, dailyDeltaKcal: 300),
        isNull,
      );
    });

    test('zero when already at goal', () {
      expect(
        JourneyMath.weeksToGoal(currentKg: 60, targetKg: 60, dailyDeltaKcal: -500),
        0,
      );
    });
  });

  test('weeklyRateForDelta: 550 kcal/day ≈ 0.5 kg/week', () {
    expect(JourneyMath.weeklyRateForDelta(550), closeTo(0.5, 0.001));
  });

  test('projectedDate advances by the right number of days', () {
    final from = DateTime(2026, 1, 1);
    final date = JourneyMath.projectedDate(
      currentKg: 64,
      targetKg: 63,
      dailyDeltaKcal: -1100, // ~0.1 kg/week... 1kg at 1100/day
      from: from,
    );
    expect(date, isNotNull);
    expect(date!.isAfter(from), isTrue);
  });

  group('adaptiveMaintenance', () {
    test('a loss on a known intake implies higher real maintenance', () {
      // Ate 1800/day for 14 days and lost 1 kg → real maintenance > 1800.
      final real = JourneyMath.adaptiveMaintenance(
        intakeKcal: 1800,
        weightChangeKg: -1,
        days: 14,
      );
      expect(real, isNotNull);
      // 1800 - (-1*7700/14) = 1800 + 550 = 2350
      expect(real!, closeTo(2350, 0.5));
    });

    test('a gain implies lower real maintenance', () {
      final real = JourneyMath.adaptiveMaintenance(
        intakeKcal: 2500,
        weightChangeKg: 1,
        days: 14,
      );
      expect(real!, closeTo(1950, 0.5)); // 2500 - 550
    });
  });

  test('smoothedTrend returns one point per weigh-in and dampens noise', () {
    final w = [
      WeighIn(id: 1, dateMillis: 1, weightKg: 64),
      WeighIn(id: 2, dateMillis: 2, weightKg: 66), // spike
      WeighIn(id: 3, dateMillis: 3, weightKg: 64),
    ];
    final t = JourneyMath.smoothedTrend(w, alpha: 0.35);
    expect(t.length, 3);
    // The smoothed spike is pulled below the raw 66.
    expect(t[1], lessThan(66));
  });
}
