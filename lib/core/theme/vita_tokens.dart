import 'package:flutter/material.dart';

/// Vita design tokens — the single source of truth for colour, radius, spacing
/// and elevation. Never hard-code a colour or radius in a widget; pull it from
/// here (or from [Theme.of(context)] which is built from these).
///
/// Brand: living emerald. One electric-lime accent reserved for the single most
/// important number (the energy ring). Ember for the calorie flame. A macro
/// trio kept perceptually distinct (protein / carbs / fat).
class VitaColors {
  const VitaColors._();

  // Brand
  static const emerald = Color(0xFF0E9E6E);
  static const emeraldDeep = Color(0xFF0B7C57);
  static const emeraldDark = Color(0xFF25C088); // brand on dark ground
  static const lime = Color(0xFFCDE84B); // hero accent — use sparingly
  static const ember = Color(0xFFFF6A3D); // energy / flame

  // Macro data trio
  static const protein = Color(0xFFF0508A);
  static const carbs = Color(0xFFF2B035);
  static const fat = Color(0xFF5C7CFA);

  // Semantic (kept separate from the brand accent)
  static const good = Color(0xFF0E9E6E);
  static const warn = Color(0xFFF2B035);
  static const crit = Color(0xFFE5484D);

  // --- Light neutrals (warm-biased, chosen not defaulted) ---
  static const lPaper = Color(0xFFF5F4EC);
  static const lCard = Color(0xFFFFFFFF);
  static const lInk = Color(0xFF181B18);
  static const lInkSoft = Color(0xFF3C433C);
  static const lMuted = Color(0xFF6D766C);
  static const lLine = Color(0xFFE4E2D6);
  static const lLineSoft = Color(0xFFEEEDE3);

  // --- Dark neutrals (deep-pine ground) ---
  static const dGround = Color(0xFF0B120F);
  static const dPaper = Color(0xFF0F1613);
  static const dCard = Color(0xFF16201B);
  static const dInk = Color(0xFFECEFEA);
  static const dInkSoft = Color(0xFFC4CCC2);
  static const dMuted = Color(0xFF8C948A);
  static const dLine = Color(0xFF26332C);
  static const dLineSoft = Color(0xFF1C2721);
}

/// Semantic colour set resolved for the active brightness. Access via
/// `context.vita` (see extension in vita_theme.dart).
class VitaPalette {
  const VitaPalette({
    required this.brightness,
    required this.ground,
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.lineSoft,
    required this.brand,
    required this.brandDeep,
  });

  final Brightness brightness;
  final Color ground; // scaffold background
  final Color paper; // inset surfaces (screen background of phone)
  final Color card; // raised cards
  final Color ink; // primary text
  final Color inkSoft; // secondary text
  final Color muted; // tertiary text / captions
  final Color line; // borders
  final Color lineSoft; // faint dividers / tracks
  final Color brand; // emerald resolved for brightness
  final Color brandDeep;

  // Constant accents (identical across themes)
  Color get lime => VitaColors.lime;
  Color get ember => VitaColors.ember;
  Color get protein => VitaColors.protein;
  Color get carbs => VitaColors.carbs;
  Color get fat => VitaColors.fat;
  bool get isDark => brightness == Brightness.dark;

  static const light = VitaPalette(
    brightness: Brightness.light,
    ground: VitaColors.lPaper,
    paper: VitaColors.lPaper,
    card: VitaColors.lCard,
    ink: VitaColors.lInk,
    inkSoft: VitaColors.lInkSoft,
    muted: VitaColors.lMuted,
    line: VitaColors.lLine,
    lineSoft: VitaColors.lLineSoft,
    brand: VitaColors.emerald,
    brandDeep: VitaColors.emeraldDeep,
  );

  static const dark = VitaPalette(
    brightness: Brightness.dark,
    ground: VitaColors.dGround,
    paper: VitaColors.dPaper,
    card: VitaColors.dCard,
    ink: VitaColors.dInk,
    inkSoft: VitaColors.dInkSoft,
    muted: VitaColors.dMuted,
    line: VitaColors.dLine,
    lineSoft: VitaColors.dLineSoft,
    brand: VitaColors.emeraldDark,
    brandDeep: VitaColors.emerald,
  );
}

/// Spacing, radius and motion constants.
class VitaSpace {
  const VitaSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 32;
}

class VitaRadius {
  const VitaRadius._();
  static const double card = 22;
  static const double sm = 14;
  static const double pill = 999;
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius smR = BorderRadius.all(Radius.circular(sm));
}

class VitaMotion {
  const VitaMotion._();
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 360);
  static const slow = Duration(milliseconds: 900);
  static const reveal = Duration(milliseconds: 1200);
  static const Curve curve = Curves.easeOutCubic;
}
