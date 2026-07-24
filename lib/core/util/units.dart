/// Unit conversion helpers. Metric is the single source of truth internally
/// (kg + cm); imperial is a display concern. The kg/cm ↔ lb/ft toggle is a
/// first-class differentiator over the competitor.

library;

enum UnitSystem { metric, imperial }

class Units {
  const Units._();

  static const double kgPerLb = 0.45359237;
  static const double cmPerInch = 2.54;

  static double kgToLb(double kg) => kg / kgPerLb;
  static double lbToKg(double lb) => lb * kgPerLb;

  static double cmToInches(double cm) => cm / cmPerInch;

  /// Split centimetres into whole feet + inches (inches rounded).
  static (int feet, int inches) cmToFeetInches(double cm) {
    final totalInches = (cm / cmPerInch).round();
    return (totalInches ~/ 12, totalInches % 12);
  }

  static double feetInchesToCm(int feet, int inches) =>
      ((feet * 12) + inches) * cmPerInch;

  /// Display weight in the active system, rounded to 1 dp.
  static double displayWeight(double kg, UnitSystem system) =>
      system == UnitSystem.metric ? kg : kgToLb(kg);

  /// Convert a displayed weight back to kg for storage.
  static double weightToKg(double value, UnitSystem system) =>
      system == UnitSystem.metric ? value : lbToKg(value);

  static String weightUnit(UnitSystem system) =>
      system == UnitSystem.metric ? 'kg' : 'lb';
}
