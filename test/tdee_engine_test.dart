// Unit tests for the TDEE calculation engine.
// Run with:  dart test
//
// Adjust the import to match your package path once the engine lives in your
// Flutter project, e.g.  import 'package:your_app/core/tdee_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/tdee_engine.dart';

void main() {
  // Reference profile used across tests: male, 20 yr, 64 kg, 5'9" (175.26 cm).
  final male = UserProfile.imperialHeight(
    sex: Sex.male,
    age: 20,
    weightKg: 64,
    feet: 5,
    inches: 9,
    activity: ActivityLevel.sedentary,
    goal: Goal.maintainWeight,
  );

  group('Height conversion', () {
    test('ft/in → cm', () {
      expect(male.heightCm, closeTo(175.26, 0.001));
    });
  });

  group('BMR — Mifflin–St Jeor', () {
    test('male constant (+5)', () {
      expect(TdeeCalculator.bmrMifflin(male), closeTo(1640.38, 0.1));
    });

    test('female constant (−161) differs by 166 at same inputs', () {
      final female = UserProfile(
        sex: Sex.female,
        age: 20,
        weightKg: 64,
        heightCm: 175.26,
        activity: ActivityLevel.sedentary,
        goal: Goal.maintainWeight,
      );
      expect(TdeeCalculator.bmrMifflin(female), closeTo(1474.38, 0.1));
      expect(
        TdeeCalculator.bmrMifflin(male) - TdeeCalculator.bmrMifflin(female),
        closeTo(166, 0.001),
      );
    });

    test('bmr() uses Mifflin when no body-fat supplied', () {
      expect(TdeeCalculator.bmr(male), TdeeCalculator.bmrMifflin(male));
    });
  });

  group('BMR — Katch–McArdle auto-upgrade', () {
    test('bmr() switches to Katch when body-fat % is provided', () {
      final withBf = UserProfile(
        sex: Sex.male,
        age: 20,
        weightKg: 64,
        heightCm: 175.26,
        activity: ActivityLevel.sedentary,
        goal: Goal.maintainWeight,
        bodyFatPercent: 15,
      );
      // LBM = 64 * 0.85 = 54.4 ; BMR = 370 + 21.6*54.4 = 1545.04
      expect(TdeeCalculator.bmr(withBf), closeTo(1545.04, 0.1));
    });
  });

  group('TDEE & PAL', () {
    test('TDEE = BMR × PAL (sedentary)', () {
      expect(TdeeCalculator.tdee(male), closeTo(1968.45, 0.1));
    });

    test('PAL breakdown scales BMR by every multiplier', () {
      final b = TdeeCalculator.bmr(male);
      final pal = TdeeCalculator.palBreakdown(male);
      expect(pal[ActivityLevel.moderate], closeTo(b * 1.55, 0.001));
      expect(pal[ActivityLevel.extreme], closeTo(b * 1.90, 0.001));
    });
  });

  group('BMI', () {
    test('value & category', () {
      expect(TdeeCalculator.bmi(male), closeTo(20.84, 0.01));
      expect(TdeeCalculator.bmiCategory(TdeeCalculator.bmi(male)),
          BmiCategory.normal);
    });

    test('category thresholds', () {
      expect(TdeeCalculator.bmiCategory(18.4), BmiCategory.underweight);
      expect(TdeeCalculator.bmiCategory(24.9), BmiCategory.normal);
      expect(TdeeCalculator.bmiCategory(27), BmiCategory.overweight);
      expect(TdeeCalculator.bmiCategory(32), BmiCategory.obese1);
      expect(TdeeCalculator.bmiCategory(41), BmiCategory.obese3);
    });

    test('BMI Prime', () {
      expect(TdeeCalculator.bmiPrime(25), closeTo(1.0, 0.0001));
    });
  });

  group('Body composition — Deurenberg', () {
    test('adult body-fat %', () {
      expect(TdeeCalculator.bodyFatPercent(male), closeTo(13.41, 0.05));
    });

    test('lean + fat mass sum to body weight', () {
      final bf = TdeeCalculator.bodyFatPercent(male);
      final lbm = TdeeCalculator.leanMassKg(male, bf);
      final fm = TdeeCalculator.fatMassKg(male, bf);
      expect(lbm + fm, closeTo(male.weightKg, 0.0001));
    });

    test('child formula applies at age ≤ 15', () {
      final child = UserProfile(
        sex: Sex.male,
        age: 12,
        weightKg: 40,
        heightCm: 150,
        activity: ActivityLevel.light,
        goal: Goal.maintainWeight,
      );
      final bmi = TdeeCalculator.bmi(child); // 17.78
      final expected = (1.51 * bmi) - (0.70 * 12) - (3.6 * 1) + 1.4;
      expect(TdeeCalculator.bodyFatPercent(child), closeTo(expected, 0.001));
    });
  });

  group('Ideal body weight', () {
    test('four formulas and the reported range (5\'9" male)', () {
      final ibw = TdeeCalculator.ibw(male);
      expect(ibw.devine, closeTo(70.7, 0.05));
      expect(ibw.robinson, closeTo(69.1, 0.05));
      expect(ibw.miller, closeTo(68.89, 0.05));
      expect(ibw.hamwi, closeTo(72.3, 0.05));
      expect(ibw.minKg, closeTo(68.89, 0.05));
      expect(ibw.maxKg, closeTo(72.3, 0.05));
    });
  });

  group('Macros', () {
    test('grams reconvert to the target calories', () {
      final m = TdeeCalculator.macros(2000, CarbProfile.moderate);
      final kcal = m.proteinG * 4 + m.fatG * 9 + m.carbG * 4;
      expect(kcal, closeTo(2000, 0.001));
    });

    test('moderate split proportions', () {
      final m = TdeeCalculator.macros(2000, CarbProfile.moderate);
      expect(m.proteinG, closeTo(2000 * 0.30 / 4, 0.001)); // 150 g
      expect(m.fatG, closeTo(2000 * 0.35 / 9, 0.001)); // ~77.8 g
      expect(m.carbG, closeTo(2000 * 0.35 / 4, 0.001)); // 175 g
    });

    test('macro matrix covers 3 modes × 3 profiles', () {
      final matrix = TdeeCalculator.macroMatrix(male);
      expect(matrix.length, 3);
      expect(matrix[CalorieMode.maintain]!.length, 3);
    });
  });

  group('Calorie targets', () {
    test('cutting & bulking factors', () {
      final maint = TdeeCalculator.maintenanceCalories(male);
      expect(TdeeCalculator.calorieForMode(male, CalorieMode.cutting),
          closeTo(maint * 0.73, 0.001));
      expect(TdeeCalculator.calorieForMode(male, CalorieMode.bulking),
          closeTo(maint * 1.25, 0.001));
    });

    test('energy-intake lose targets', () {
      final maint = TdeeCalculator.maintenanceCalories(male);
      final lose = TdeeCalculator.energyIntake(male, lose: true);
      expect(lose['mild_0.25'], closeTo(maint * 0.90, 0.001));
      expect(lose['extreme_1.0'], closeTo(maint * 0.61, 0.001));
    });

    test('daily delta from a weekly rate (7700 kcal/kg)', () {
      expect(TdeeCalculator.dailyDeltaForRate(0.5), closeTo(550, 0.001));
      expect(TdeeCalculator.dailyDeltaForRate(1.0), closeTo(1100, 0.001));
    });
  });

  group('computeAll aggregates everything', () {
    test('returns a fully-populated result', () {
      final r = TdeeCalculator.computeAll(male);
      expect(r.bmr, closeTo(1640.38, 0.1));
      expect(r.tdee, closeTo(1968.45, 0.1));
      expect(r.bmiCategory, BmiCategory.normal);
      expect(r.ibw.minKg, closeTo(68.89, 0.05));
      expect(r.palBreakdown.length, 5);
      expect(r.loseTargets.length, 3);
      expect(r.gainTargets.length, 3);
    });
  });
}
