import 'package:flutter/foundation.dart';

/// A single seam for crash + error reporting.
///
/// It logs to the console today. To enable Firebase Crashlytics or Sentry,
/// add the package + platform config and forward the two `record*` methods —
/// no call sites change (main.dart already routes every uncaught error here).
///
///   // Crashlytics example:
///   // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
///   // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  void recordFlutterError(FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    // TODO(release): FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  void recordError(Object error, StackTrace stack) {
    debugPrint('Uncaught: $error\n$stack');
    // TODO(release): FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }

  /// Attach a breadcrumb / non-fatal log.
  void log(String message) {
    debugPrint('[log] $message');
    // TODO(release): FirebaseCrashlytics.instance.log(message);
  }
}
