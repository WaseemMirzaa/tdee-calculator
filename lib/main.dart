import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/providers/app_providers.dart';
import 'core/services/ads_service.dart';
import 'core/services/crash_reporter.dart';

Future<void> main() async {
  // runZonedGuarded + FlutterError.onError catch every uncaught error so a
  // crash reporter (Crashlytics/Sentry) can be dropped into CrashReporter
  // without touching call sites. See crash_reporter.dart.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      CrashReporter.instance.recordFlutterError(details);
    };

    final container = ProviderContainer();

    // Warm up persisted state so the first frame is correct (no theme/unit
    // flash) and the router's redirect sees the real profile.
    await container.read(dbProvider).preloadSettings();
    await container.read(profileProvider.future);
    container.read(themeModeProvider);
    container.read(schemeProvider);
    container.read(unitSystemProvider);
    container.read(selectedDietProvider);

    // Ads (free, ad-supported) — gather consent, then initialise. Best-effort.
    unawaited(AdsService.instance.bootstrap());

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const VitaApp(),
      ),
    );
  }, (error, stack) {
    CrashReporter.instance.recordError(error, stack);
  });
}

/// Kept as a hook for tests / future DI.
AppDatabase get appDatabase => AppDatabase.instance;
