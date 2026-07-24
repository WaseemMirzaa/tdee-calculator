// TDEE calculation engine — pure Dart, no Flutter imports.
//
// All coefficients verified against source papers (see project brief §4).
// Inputs: weight kg, height cm, age years. Where a formula takes `sex`,
// it is coded male = 1, female = 0.
//
// The UI layer should call [TdeeCalculator.computeAll] once and read from
// the returned [TdeeResult]; do not recompute piecemeal in widgets.

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, veryActive, extreme }

enum Goal { loseWeight, maintainWeight, gainWeight }

enum CarbProfile { moderate, lower, high }

enum CalorieMode { maintain, cutting, bulking }

enum BmiCategory { underweight, normal, overweight, obese1, obese2, obese3 }

/// Which BMR/RMR equation to use. [auto] picks Mifflin, upgrading to
/// Katch–McArdle automatically when a body-fat % is supplied.
enum BmrFormula { auto, mifflin, katchMcArdle, harrisRevised, harrisOriginal }

// ---------------------------------------------------------------------------
// Config — every tunable constant lives here. Never hard-code these elsewhere.
// ---------------------------------------------------------------------------

class TdeeConfig {
  const TdeeConfig({
    this.pal = const {
      ActivityLevel.sedentary: 1.20,
      ActivityLevel.light: 1.375,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.veryActive: 1.725,
      ActivityLevel.extreme: 1.90,
    },
    this.macroSplit = const {
      // profile: [protein%, fat%, carbs%]
      CarbProfile.moderate: [0.30, 0.35, 0.35],
      CarbProfile.lower: [0.40, 0.40, 0.20],
      CarbProfile.high: [0.30, 0.20, 0.50],
    },
    this.cuttingFactor = 0.73,
    this.bulkingFactor = 1.25,
    this.loseFactors = const {
      'mild_0.25': 0.90,
      'loss_0.5': 0.80,
      'extreme_1.0': 0.61,
    },
    this.gainFactors = const {
      'mild_0.25': 1.10,
      'gain_0.5': 1.20,
      'extreme_1.0': 1.39,
    },
    this.kcalPerGProtein = 4,
    this.kcalPerGCarb = 4,
    this.kcalPerGFat = 9,
    this.kcalPerKgFat = 7700,
  });

  final Map<ActivityLevel, double> pal;

  /// profile -> [proteinFraction, fatFraction, carbFraction].
  final Map<CarbProfile, List<double>> macroSplit;

  final double cuttingFactor;
  final double bulkingFactor;

  /// rate-key -> fraction of maintenance calories.
  final Map<String, double> loseFactors;
  final Map<String, double> gainFactors;

  final double kcalPerGProtein;
  final double kcalPerGCarb;
  final double kcalPerGFat;
  final double kcalPerKgFat;

  static const TdeeConfig standard = TdeeConfig();
}

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

class UserProfile {
  UserProfile({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activity,
    required this.goal,
    this.name,
    this.bodyFatPercent,
  });

  /// Convenience constructor that accepts height in feet + inches and
  /// converts to centimetres internally (metric is the single source of truth).
  factory UserProfile.imperialHeight({
    required Sex sex,
    required int age,
    required double weightKg,
    required int feet,
    required int inches,
    required ActivityLevel activity,
    required Goal goal,
    String? name,
    double? bodyFatPercent,
  }) {
    final totalInches = (feet * 12) + inches;
    return UserProfile(
      sex: sex,
      age: age,
      weightKg: weightKg,
      heightCm: totalInches * 2.54,
      activity: activity,
      goal: goal,
      name: name,
      bodyFatPercent: bodyFatPercent,
    );
  }

  Sex sex;
  int age;
  double weightKg;
  double heightCm;
  ActivityLevel activity;
  Goal goal;
  String? name;

  /// Optional body-fat %. When present, [TdeeCalculator.bmr] auto-upgrades to
  /// the Katch–McArdle equation.
  double? bodyFatPercent;

  /// sex encoded as male = 1, female = 0 for the formulas that need it.
  int get sexCode => sex == Sex.male ? 1 : 0;

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? weightKg,
    double? heightCm,
    ActivityLevel? activity,
    Goal? goal,
    String? name,
    double? bodyFatPercent,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      name: name ?? this.name,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
    );
  }
}

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

class Macros {
  const Macros({
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
  });

  final double calories;
  final double proteinG;
  final double fatG;
  final double carbG;
}

class IbwRange {
  const IbwRange({
    required this.minKg,
    required this.maxKg,
    required this.devine,
    required this.robinson,
    required this.miller,
    required this.hamwi,
  });

  final double minKg;
  final double maxKg;
  final double devine;
  final double robinson;
  final double miller;
  final double hamwi;
}

class TdeeResult {
  const TdeeResult({
    required this.bmr,
    required this.rmr,
    required this.tdee,
    required this.bmi,
    required this.bmiCategory,
    required this.bmiPrime,
    required this.bodyFatPercent,
    required this.leanMassKg,
    required this.fatMassKg,
    required this.ibw,
    required this.palBreakdown,
    required this.maintenanceCalories,
    required this.macroMatrix,
    required this.loseTargets,
    required this.gainTargets,
  });

  final double bmr;
  final double rmr;
  final double tdee;
  final double bmi;
  final BmiCategory bmiCategory;
  final double bmiPrime;
  final double bodyFatPercent;
  final double leanMassKg;
  final double fatMassKg;
  final IbwRange ibw;
  final Map<ActivityLevel, double> palBreakdown;
  final double maintenanceCalories;
  final Map<CalorieMode, Map<CarbProfile, Macros>> macroMatrix;

  /// rate-key -> calories/day for the three weight-loss rates.
  final Map<String, double> loseTargets;

  /// rate-key -> calories/day for the three weight-gain rates.
  final Map<String, double> gainTargets;
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

class TdeeCalculator {
  const TdeeCalculator._();

  static const TdeeConfig config = TdeeConfig.standard;

  // --- BMR / RMR ----------------------------------------------------------

  static double bmrMifflin(UserProfile p) {
    final base = (10 * p.weightKg) + (6.25 * p.heightCm) - (5 * p.age);
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  static double bmrKatchMcArdle(UserProfile p, {double? bodyFatPercent}) {
    final bf = bodyFatPercent ?? p.bodyFatPercent ?? 0;
    final lbm = p.weightKg * (1 - bf / 100);
    return 370 + (21.6 * lbm);
  }

  static double bmrHarrisRevised(UserProfile p) {
    return p.sex == Sex.male
        ? 88.362 + (13.397 * p.weightKg) + (4.799 * p.heightCm) - (5.677 * p.age)
        : 447.593 + (9.247 * p.weightKg) + (3.098 * p.heightCm) - (4.330 * p.age);
  }

  static double bmrHarrisOriginal(UserProfile p) {
    return p.sex == Sex.male
        ? 66.47 + (13.75 * p.weightKg) + (5.003 * p.heightCm) - (6.755 * p.age)
        : 655.1 + (9.563 * p.weightKg) + (1.850 * p.heightCm) - (4.676 * p.age);
  }

  /// Default BMR: Mifflin–St Jeor, auto-upgraded to Katch–McArdle when a
  /// body-fat % is available (strictly more accurate when that data exists).
  static double bmr(UserProfile p, {BmrFormula formula = BmrFormula.auto}) {
    switch (formula) {
      case BmrFormula.mifflin:
        return bmrMifflin(p);
      case BmrFormula.katchMcArdle:
        return bmrKatchMcArdle(p);
      case BmrFormula.harrisRevised:
        return bmrHarrisRevised(p);
      case BmrFormula.harrisOriginal:
        return bmrHarrisOriginal(p);
      case BmrFormula.auto:
        return p.bodyFatPercent != null ? bmrKatchMcArdle(p) : bmrMifflin(p);
    }
  }

  /// RMR is a distinct stored field but computed identically to BMR.
  static double rmr(UserProfile p) => bmr(p);

  // --- TDEE / PAL ---------------------------------------------------------

  static double tdee(UserProfile p, {TdeeConfig cfg = config}) {
    return bmr(p) * cfg.pal[p.activity]!;
  }

  static Map<ActivityLevel, double> palBreakdown(
    UserProfile p, {
    TdeeConfig cfg = config,
  }) {
    final b = bmr(p);
    return {
      for (final entry in cfg.pal.entries) entry.key: b * entry.value,
    };
  }

  // --- BMI ----------------------------------------------------------------

  static double bmi(UserProfile p) {
    final hM = p.heightCm / 100;
    return p.weightKg / (hM * hM);
  }

  static BmiCategory bmiCategory(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    if (bmi < 35) return BmiCategory.obese1;
    if (bmi < 40) return BmiCategory.obese2;
    return BmiCategory.obese3;
  }

  static double bmiPrime(double bmi) => bmi / 25;

  // --- Body composition (Deurenberg 1991) --------------------------------

  static double bodyFatPercent(UserProfile p) {
    final b = bmi(p);
    if (p.age <= 15) {
      // Child formula.
      return (1.51 * b) - (0.70 * p.age) - (3.6 * p.sexCode) + 1.4;
    }
    // Adult formula.
    return (1.20 * b) + (0.23 * p.age) - (10.8 * p.sexCode) - 5.4;
  }

  static double leanMassKg(UserProfile p, double bodyFat) {
    return p.weightKg * (1 - bodyFat / 100);
  }

  static double fatMassKg(UserProfile p, double bodyFat) {
    return p.weightKg - leanMassKg(p, bodyFat);
  }

  // --- Ideal body weight --------------------------------------------------

  static IbwRange ibw(UserProfile p) {
    final i = (p.heightCm / 2.54) - 60; // inches over 5 ft; may be negative.
    final male = p.sex == Sex.male;
    final devine = male ? 50 + 2.3 * i : 45.5 + 2.3 * i;
    final robinson = male ? 52 + 1.9 * i : 49 + 1.7 * i;
    final miller = male ? 56.2 + 1.41 * i : 53.1 + 1.36 * i;
    final hamwi = male ? 48 + 2.7 * i : 45.5 + 2.2 * i;
    final all = [devine, robinson, miller, hamwi];
    return IbwRange(
      minKg: all.reduce(math.min),
      maxKg: all.reduce(math.max),
      devine: devine,
      robinson: robinson,
      miller: miller,
      hamwi: hamwi,
    );
  }

  // --- Calorie targets ----------------------------------------------------

  static double maintenanceCalories(UserProfile p) => tdee(p);

  static double calorieForMode(
    UserProfile p,
    CalorieMode mode, {
    TdeeConfig cfg = config,
  }) {
    final maint = maintenanceCalories(p);
    switch (mode) {
      case CalorieMode.maintain:
        return maint;
      case CalorieMode.cutting:
        return maint * cfg.cuttingFactor;
      case CalorieMode.bulking:
        return maint * cfg.bulkingFactor;
    }
  }

  // --- Macros -------------------------------------------------------------

  static Macros macros(
    double calories,
    CarbProfile profile, {
    TdeeConfig cfg = config,
  }) {
    final split = cfg.macroSplit[profile]!;
    final proteinPct = split[0];
    final fatPct = split[1];
    final carbPct = split[2];
    return Macros(
      calories: calories,
      proteinG: (calories * proteinPct) / cfg.kcalPerGProtein,
      fatG: (calories * fatPct) / cfg.kcalPerGFat,
      carbG: (calories * carbPct) / cfg.kcalPerGCarb,
    );
  }

  static Map<CalorieMode, Map<CarbProfile, Macros>> macroMatrix(
    UserProfile p, {
    TdeeConfig cfg = config,
  }) {
    return {
      for (final mode in CalorieMode.values)
        mode: {
          for (final profile in CarbProfile.values)
            profile: macros(calorieForMode(p, mode, cfg: cfg), profile, cfg: cfg),
        },
    };
  }

  // --- Energy intake ------------------------------------------------------

  static Map<String, double> energyIntake(
    UserProfile p, {
    required bool lose,
    TdeeConfig cfg = config,
  }) {
    final maint = maintenanceCalories(p);
    final factors = lose ? cfg.loseFactors : cfg.gainFactors;
    return {
      for (final entry in factors.entries) entry.key: maint * entry.value,
    };
  }

  /// Daily calorie delta implied by a target weekly rate of change (kg/week),
  /// using the 7 700 kcal ≈ 1 kg body-fat constant.
  static double dailyDeltaForRate(double kgPerWeek, {TdeeConfig cfg = config}) {
    return (kgPerWeek * cfg.kcalPerKgFat) / 7;
  }

  // --- Aggregate ----------------------------------------------------------

  /// Compute everything the UI needs in one pass.
  static TdeeResult computeAll(UserProfile p, {TdeeConfig cfg = config}) {
    final b = bmr(p);
    final bmiValue = bmi(p);
    final bf = bodyFatPercent(p);
    return TdeeResult(
      bmr: b,
      rmr: rmr(p),
      tdee: tdee(p, cfg: cfg),
      bmi: bmiValue,
      bmiCategory: bmiCategory(bmiValue),
      bmiPrime: bmiPrime(bmiValue),
      bodyFatPercent: bf,
      leanMassKg: leanMassKg(p, bf),
      fatMassKg: fatMassKg(p, bf),
      ibw: ibw(p),
      palBreakdown: palBreakdown(p, cfg: cfg),
      maintenanceCalories: maintenanceCalories(p),
      macroMatrix: macroMatrix(p, cfg: cfg),
      loseTargets: energyIntake(p, lose: true, cfg: cfg),
      gainTargets: energyIntake(p, lose: false, cfg: cfg),
    );
  }
}
