import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Warm up persisted state so the splash redirect has the profile ready and
  // preferences (theme, units, premium) are restored before first frame.
  await container.read(profileProvider.future);
  container.read(premiumProvider);
  container.read(themeModeProvider);
  container.read(unitSystemProvider);

  // Initialise billing; grant entitlement when a purchase/restore lands.
  await container.read(purchaseServiceProvider).init(
        onEntitlement: (isPremium) =>
            container.read(premiumProvider.notifier).setPremium(isPremium),
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VitaApp(),
    ),
  );
}
