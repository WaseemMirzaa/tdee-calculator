import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/vita_tokens.dart';
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
      builder: (context, child) {
        // Apply the correct status-bar style app-wide, including screens with no
        // AppBar (home shell, onboarding). Re-evaluates on theme change.
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final ground = isDark ? VitaColors.dGround : VitaColors.lPaper;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: vitaOverlayStyle(isDark, ground),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
