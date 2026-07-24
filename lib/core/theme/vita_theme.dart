import 'package:flutter/material.dart';
import 'vita_tokens.dart';

/// Builds Material [ThemeData] for light and dark from Vita tokens, and exposes
/// the resolved [VitaPalette] + text styles via `context.vita` / `context.vt`.
class VitaTheme {
  const VitaTheme._();

  static ThemeData light([VitaScheme? scheme]) =>
      _build(VitaPalette.light(scheme ?? kVitaSchemes.first));
  static ThemeData dark([VitaScheme? scheme]) =>
      _build(VitaPalette.dark(scheme ?? kVitaSchemes.first));

  static ThemeData _build(VitaPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.brand,
      brightness: p.brightness,
    ).copyWith(
      primary: p.brand,
      surface: p.card,
      onSurface: p.ink,
      error: VitaColors.crit,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.ground,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[VitaThemeExt(palette: p)],
    );

    return base.copyWith(
      textTheme: _textTheme(p, base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: p.ground,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.lineSoft, thickness: 1, space: 1),
      cardTheme: CardTheme(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: VitaRadius.cardR,
          side: BorderSide(color: p.line),
        ),
      ),
    );
  }

  static TextTheme _textTheme(VitaPalette p, TextTheme base) {
    return base.copyWith(
      displayLarge: TextStyle(
          color: p.ink, fontWeight: FontWeight.w800, letterSpacing: -1.6, height: 1.02),
      headlineMedium: TextStyle(
          color: p.ink, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.06),
      titleLarge: TextStyle(
          color: p.ink, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleMedium: TextStyle(
          color: p.ink, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      bodyLarge: TextStyle(color: p.ink, height: 1.5),
      bodyMedium: TextStyle(color: p.inkSoft, height: 1.5),
      labelLarge: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(
          color: p.muted, fontWeight: FontWeight.w600, letterSpacing: 1.4),
    ).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );
  }
}

/// The monospace family used for all numeric readouts. Falls back gracefully.
const String vitaMono = 'monospace';

/// Theme extension holding the resolved palette.
class VitaThemeExt extends ThemeExtension<VitaThemeExt> {
  const VitaThemeExt({required this.palette});
  final VitaPalette palette;

  @override
  VitaThemeExt copyWith({VitaPalette? palette}) =>
      VitaThemeExt(palette: palette ?? this.palette);

  @override
  VitaThemeExt lerp(ThemeExtension<VitaThemeExt>? other, double t) => this;
}

extension VitaContext on BuildContext {
  /// Resolved Vita palette for the active theme.
  VitaPalette get vita =>
      Theme.of(this).extension<VitaThemeExt>()!.palette;

  TextTheme get vt => Theme.of(this).textTheme;

  /// A tabular-mono text style for numeric readouts.
  TextStyle mono({double size = 16, FontWeight weight = FontWeight.w700, Color? color}) {
    return TextStyle(
      fontFamily: vitaMono,
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.5,
      color: color ?? vita.ink,
    );
  }

  /// An uppercase mono label (captions, units).
  TextStyle monoLabel({double size = 11, Color? color}) {
    return TextStyle(
      fontFamily: vitaMono,
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: color ?? vita.muted,
    );
  }
}
