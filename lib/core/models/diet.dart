/// A diet type with its exclusion list (already nutritionally corrected in seed).
class Diet {
  const Diet({
    required this.id,
    required this.name,
    required this.singleSelect,
    required this.excludes,
  });

  final String id;
  final String name;
  final bool singleSelect;
  final List<String> excludes;

  /// Original, human-facing one-liner describing what the diet leaves out.
  String get exclusionLabel =>
      excludes.isEmpty ? 'Nothing off the table' : _pretty(excludes).join(' · ');

  static List<String> _pretty(List<String> raw) => raw
      .map((e) => e
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' '))
      .toList();

  factory Diet.fromJson(Map<String, dynamic> j) => Diet(
        id: j['id'] as String,
        name: j['name'] as String,
        singleSelect: j['singleSelect'] as bool? ?? true,
        excludes: (j['excludes'] as List).cast<String>(),
      );
}
