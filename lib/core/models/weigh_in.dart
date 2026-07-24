/// A logged weight measurement — the raw material of the Journey feature.
/// Pure Dart so the projection math stays unit-testable.
class WeighIn {
  const WeighIn({required this.id, required this.dateMillis, required this.weightKg});
  final int id;
  final int dateMillis;
  final double weightKg;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);
}
