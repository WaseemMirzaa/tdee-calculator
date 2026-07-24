# Vita — TDEE Calculator & Meal Planner

A freemium **TDEE / calorie calculator + meal-planning** app for iOS & Android,
built in Flutter. Full feature parity with the reference competitor, rebuilt with
an original design language ("Vita"), an improved value-first flow, and one
flagship differentiator the competitor doesn't have: **Journey** — a living
goal projection and weigh-in trend with adaptive-TDEE recalibration.

> Design & experience blueprint (understanding, flows, screen-by-screen specs):
> see the rendered blueprint shared with the team.

## Architecture

- **Offline-first.** The food/meal DB ships as a bundled JSON asset; all
  calculations run locally. No network is required for the core flow.
- **Pure engine.** `lib/core/tdee_engine.dart` has no Flutter imports and is the
  single source of truth for every formula. All tunable constants live in
  `TdeeConfig`. The UI calls `TdeeCalculator.computeAll()` **once** and reads
  from the result object.
- **Local SQL persistence.** `lib/core/db/app_database.dart` uses **sqflite**
  with hand-written SQL (no codegen) to store the profile, food likes, the
  generated meal plan, favorites, weigh-ins, and settings.
- **State:** Riverpod (`lib/core/providers/app_providers.dart`). The engine
  stays pure — no state-library imports inside `core/`.
- **One `isPremium` flag** (`premiumProvider`) gates every locked card and all
  ads. Billing uses `in_app_purchase` (Google Play Billing / StoreKit).

## Project layout

```
lib/
  core/
    tdee_engine.dart        # pure formulas (verified against golden output)
    meal_planner.dart       # meal-generation algorithm (pure, tested)
    journey_math.dart       # projections + adaptive TDEE (pure, tested)
    seed_loader.dart        # parses assets/tdee_seed.json
    models/                 # Food, Meal, Diet, SeedData, WeighIn
    db/app_database.dart    # local SQLite (sqflite)
    theme/                  # Vita tokens + ThemeData
    providers/              # Riverpod state
    services/               # purchase + ads wrappers
    util/units.dart         # kg/cm ↔ lb/ft
  features/
    onboarding/ results/ meals/ journey/ settings/ paywall/
  widgets/                  # shared design-system widgets
  app.dart  main.dart  router.dart
assets/tdee_seed.json
test/                       # engine, planner, journey, seed integrity
```

## Verified golden output

Profile: male, 20 yr, 64 kg, 5'9" (175.26 cm), sedentary →
BMR 1640 · TDEE 1968 · BMI 20.84 (normal) · Body-fat 13.4% · IBW 68.9–72.3 kg.
All 39 unit tests pass (`flutter test`).

## Running

```bash
flutter pub get
flutter test          # engine + planner + journey + seed integrity
flutter run
```

Billing and ads use store test ids / graceful fallbacks out of the box; set the
real product id in `purchase_service.dart` and ad unit ids in `ads_service.dart`
before release.
