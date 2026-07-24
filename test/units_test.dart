import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/util/units.dart';

void main() {
  group('Units', () {
    test('kg ↔ lb round-trips', () {
      expect(Units.kgToLb(100), closeTo(220.462, 0.01));
      expect(Units.lbToKg(Units.kgToLb(72.5)), closeTo(72.5, 1e-9));
    });

    test('cm → ft/in', () {
      expect(Units.cmToFeetInches(175.26), (5, 9));
      expect(Units.feetInchesToCm(5, 9), closeTo(175.26, 0.001));
    });

    test('display + back-convert weight', () {
      expect(Units.displayWeight(70, UnitSystem.metric), 70);
      expect(Units.displayWeight(70, UnitSystem.imperial), closeTo(154.32, 0.01));
      expect(Units.weightToKg(154.32, UnitSystem.imperial), closeTo(70, 0.01));
    });

    test('unit labels', () {
      expect(Units.weightUnit(UnitSystem.metric), 'kg');
      expect(Units.weightUnit(UnitSystem.imperial), 'lb');
    });
  });
}
