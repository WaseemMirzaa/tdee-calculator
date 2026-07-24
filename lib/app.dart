import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/vita_theme.dart';
import 'router.dart';

class VitaApp extends ConsumerWidget {
  const VitaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final scheme = ref.watch(schemeProvider);
    return MaterialApp.router(
      title: 'Vita',
      debugShowCheckedModeBanner: false,
      theme: VitaTheme.light(scheme),
      darkTheme: VitaTheme.dark(scheme),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
