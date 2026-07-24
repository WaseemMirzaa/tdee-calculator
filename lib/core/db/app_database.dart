import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../tdee_engine.dart';
import '../models/weigh_in.dart';
export '../models/weigh_in.dart';

/// One persisted meal-plan slot.
class PlanEntry {
  const PlanEntry({required this.day, required this.slot, required this.mealId, required this.type});
  final int day;
  final int slot;
  final String mealId;
  final String type;
}

/// A pantry item the user has on hand. [days] is the supply duration in days
/// (0 = "have it", with no countdown); the remaining supply is *derived* from
/// the number of calendar days elapsed since [startMillis], so it deducts one
/// day automatically each day with no background job.
class KitchenItem {
  const KitchenItem({required this.item, this.days = 0, this.startMillis = 0});

  final String item;
  final int days; // 0 => have-it, untracked
  final int startMillis; // date-only epoch millis when the supply was set

  bool get tracked => days > 0;

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Days of supply left today (null when untracked). Never negative.
  int? remainingDays([DateTime? now]) {
    if (days <= 0) return null;
    final start = _dateOnly(DateTime.fromMillisecondsSinceEpoch(startMillis));
    final today = _dateOnly(now ?? DateTime.now());
    final left = days - today.difference(start).inDays;
    return left < 0 ? 0 : left;
  }

  /// The calendar day the supply is expected to run out (null when untracked).
  DateTime? runOutDate() {
    if (days <= 0) return null;
    final start = _dateOnly(DateTime.fromMillisecondsSinceEpoch(startMillis));
    return start.add(Duration(days: days));
  }
}

/// The app's single local SQL database. Raw SQL, no codegen. Stores everything
/// the app needs offline: the profile, food likes, the generated meal plan,
/// meal favorites, weigh-ins, and a simple key/value settings table.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'vita.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, _dbName),
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS kitchen (item TEXT PRIMARY KEY)');
    }
    if (oldV < 3) {
      // Per-item supply tracking: how many days of the item the user has, and
      // when they set it. Existing rows become untracked "have it" (days = 0).
      await db.execute('ALTER TABLE kitchen ADD COLUMN days INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE kitchen ADD COLUMN start_millis INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        sex TEXT NOT NULL,
        age INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        activity TEXT NOT NULL,
        goal TEXT NOT NULL,
        name TEXT,
        body_fat REAL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE weigh_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_millis INTEGER NOT NULL,
        weight_kg REAL NOT NULL
      )''');
    await db.execute('CREATE INDEX idx_weigh_date ON weigh_ins(date_millis)');
    await db.execute('CREATE TABLE food_prefs (food_id TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE favorites (meal_id TEXT PRIMARY KEY)');
    await db.execute('''
      CREATE TABLE plan_entries (
        day INTEGER NOT NULL,
        slot INTEGER NOT NULL,
        meal_id TEXT NOT NULL,
        type TEXT NOT NULL,
        PRIMARY KEY (day, slot)
      )''');
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
    await db.execute(
        'CREATE TABLE kitchen (item TEXT PRIMARY KEY, days INTEGER NOT NULL DEFAULT 0, start_millis INTEGER NOT NULL DEFAULT 0)');
  }

  // --- Kitchen / pantry (items the user already has) ----------------------

  Future<List<KitchenItem>> loadKitchen() async {
    final db = await _database;
    final rows = await db.query('kitchen');
    return rows
        .map((r) => KitchenItem(
              item: r['item'] as String,
              days: (r['days'] as int?) ?? 0,
              startMillis: (r['start_millis'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<void> setKitchen(List<KitchenItem> items) async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('kitchen');
    for (final it in items) {
      batch.insert('kitchen', {
        'item': it.item,
        'days': it.days,
        'start_millis': it.startMillis,
      });
    }
    await batch.commit(noResult: true);
  }

  // --- Profile ------------------------------------------------------------

  Future<void> saveProfile(UserProfile p) async {
    final db = await _database;
    await db.insert(
      'profile',
      {
        'id': 1,
        'sex': p.sex.name,
        'age': p.age,
        'weight_kg': p.weightKg,
        'height_cm': p.heightCm,
        'activity': p.activity.name,
        'goal': p.goal.name,
        'name': p.name,
        'body_fat': p.bodyFatPercent,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> loadProfile() async {
    final db = await _database;
    final rows = await db.query('profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserProfile(
      sex: Sex.values.byName(r['sex'] as String),
      age: r['age'] as int,
      weightKg: (r['weight_kg'] as num).toDouble(),
      heightCm: (r['height_cm'] as num).toDouble(),
      activity: ActivityLevel.values.byName(r['activity'] as String),
      goal: Goal.values.byName(r['goal'] as String),
      name: r['name'] as String?,
      bodyFatPercent: (r['body_fat'] as num?)?.toDouble(),
    );
  }

  Future<bool> hasProfile() async => (await loadProfile()) != null;

  // --- Food preferences ---------------------------------------------------

  Future<void> setFoodPrefs(Set<String> foodIds) async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('food_prefs');
    for (final id in foodIds) {
      batch.insert('food_prefs', {'food_id': id});
    }
    await batch.commit(noResult: true);
  }

  Future<Set<String>> loadFoodPrefs() async {
    final db = await _database;
    final rows = await db.query('food_prefs');
    return rows.map((r) => r['food_id'] as String).toSet();
  }

  // --- Favorites ----------------------------------------------------------

  Future<void> toggleFavorite(String mealId) async {
    final db = await _database;
    final existing = await db.query('favorites', where: 'meal_id = ?', whereArgs: [mealId]);
    if (existing.isEmpty) {
      await db.insert('favorites', {'meal_id': mealId});
    } else {
      await db.delete('favorites', where: 'meal_id = ?', whereArgs: [mealId]);
    }
  }

  Future<Set<String>> loadFavorites() async {
    final db = await _database;
    final rows = await db.query('favorites');
    return rows.map((r) => r['meal_id'] as String).toSet();
  }

  // --- Meal plan ----------------------------------------------------------

  Future<void> savePlan(List<PlanEntry> entries) async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('plan_entries');
    for (final e in entries) {
      batch.insert('plan_entries', {
        'day': e.day,
        'slot': e.slot,
        'meal_id': e.mealId,
        'type': e.type,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<PlanEntry>> loadPlan() async {
    final db = await _database;
    final rows = await db.query('plan_entries', orderBy: 'day ASC, slot ASC');
    return rows
        .map((r) => PlanEntry(
              day: r['day'] as int,
              slot: r['slot'] as int,
              mealId: r['meal_id'] as String,
              type: r['type'] as String,
            ))
        .toList();
  }

  // --- Weigh-ins (Journey) ------------------------------------------------

  Future<int> addWeighIn(DateTime date, double weightKg) async {
    final db = await _database;
    return db.insert('weigh_ins', {
      'date_millis': date.millisecondsSinceEpoch,
      'weight_kg': weightKg,
    });
  }

  Future<void> deleteWeighIn(int id) async {
    final db = await _database;
    await db.delete('weigh_ins', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WeighIn>> loadWeighIns() async {
    final db = await _database;
    final rows = await db.query('weigh_ins', orderBy: 'date_millis ASC');
    return rows
        .map((r) => WeighIn(
              id: r['id'] as int,
              dateMillis: r['date_millis'] as int,
              weightKg: (r['weight_kg'] as num).toDouble(),
            ))
        .toList();
  }

  // --- Settings (key/value) ----------------------------------------------

  /// Synchronous mirror of the settings table, filled by [preloadSettings] at
  /// startup so preference providers (theme, units, diet) read the persisted
  /// value on the FIRST frame — no flash of defaults.
  final Map<String, String> settingsCache = {};

  Future<void> preloadSettings() async {
    final db = await _database;
    final rows = await db.query('settings');
    settingsCache.clear();
    for (final r in rows) {
      settingsCache[r['key'] as String] = r['value'] as String;
    }
  }

  /// Synchronous read from the preloaded cache.
  String? getSettingSync(String key) => settingsCache[key];

  Future<void> setSetting(String key, String value) async {
    settingsCache[key] = value;
    final db = await _database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await _database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// Wipe everything (used by "Reset" flows).
  Future<void> clearAll() async {
    settingsCache.clear();
    final db = await _database;
    final batch = db.batch();
    for (final t in ['profile', 'weigh_ins', 'food_prefs', 'favorites', 'plan_entries', 'settings', 'kitchen']) {
      batch.delete(t);
    }
    await batch.commit(noResult: true);
  }
}
