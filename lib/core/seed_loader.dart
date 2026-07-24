import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models/seed_data.dart';

/// Loads and parses the bundled seed database from assets. Offline-first: no
/// network is ever touched.
class SeedLoader {
  const SeedLoader._();

  static const String assetPath = 'assets/tdee_seed.json';

  static SeedData? _cache;

  /// Parse the seed asset once and cache it for the app lifetime.
  static Future<SeedData> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = SeedData.fromJson(json);
    return _cache!;
  }

  /// Parse from an already-loaded string (used in tests).
  static SeedData parse(String raw) =>
      SeedData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
