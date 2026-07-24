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

/// A selectable premium accent scheme (brand + deep + hero accent). The user
/// picks one in Settings; it's persisted and drives every branded surface.
class VitaScheme {
  const VitaScheme({
    required this.id,
    required this.name,
    required this.brandLight,
    required this.brandDeepLight,
    required this.brandDark,
    required this.accent,
  });

  final String id;
  final String name;
  final Color brandLight; // brand on light ground
  final Color brandDeepLight; // deeper brand for gradients
  final Color brandDark; // brand on dark ground
  final Color accent; // the single bright hero accent (the ring highlight)
}

/// Ten curated premium schemes — each one recolours the *entire* surface set
/// (grounds, cards, lines, text) toward its hue, not just the accent. Emerald
/// is the default. The first six are the originals; the last four are new.
const List<VitaScheme> kVitaSchemes = [
  VitaScheme(
    id: 'emerald', name: 'Emerald',
    brandLight: Color(0xFF0E9E6E), brandDeepLight: Color(0xFF0B7C57),
    brandDark: Color(0xFF25C088), accent: Color(0xFFCDE84B),
  ),
  VitaScheme(
    id: 'indigo', name: 'Indigo',
    brandLight: Color(0xFF5B6CF0), brandDeepLight: Color(0xFF3F4CC0),
    brandDark: Color(0xFF8A97F7), accent: Color(0xFF6FE6FF),
  ),
  VitaScheme(
    id: 'violet', name: 'Violet',
    brandLight: Color(0xFF8B5CF6), brandDeepLight: Color(0xFF6D3EE0),
    brandDark: Color(0xFFA78BFA), accent: Color(0xFFF3A9FF),
  ),
  VitaScheme(
    id: 'sunset', name: 'Sunset',
    brandLight: Color(0xFFF5623D), brandDeepLight: Color(0xFFD8431F),
    brandDark: Color(0xFFFF7E57), accent: Color(0xFFFFC24A),
  ),
  VitaScheme(
    id: 'rose', name: 'Rose',
    brandLight: Color(0xFFF0508A), brandDeepLight: Color(0xFFD62E6E),
    brandDark: Color(0xFFFF6FA3), accent: Color(0xFFFFB27A),
  ),
  VitaScheme(
    id: 'ocean', name: 'Ocean',
    brandLight: Color(0xFF0EA5B5), brandDeepLight: Color(0xFF077C88),
    brandDark: Color(0xFF29C6D4), accent: Color(0xFF8CF0D0),
  ),
  // --- New schemes ---
  VitaScheme(
    id: 'amber', name: 'Amber',
    brandLight: Color(0xFFB5820E), brandDeepLight: Color(0xFF8A6209),
    brandDark: Color(0xFFE7B94D), accent: Color(0xFFFFD66B),
  ),
  VitaScheme(
    id: 'crimson', name: 'Crimson',
    brandLight: Color(0xFFD62839), brandDeepLight: Color(0xFFA81E2C),
    brandDark: Color(0xFFF25563), accent: Color(0xFFFF9E7A),
  ),
  VitaScheme(
    id: 'slate', name: 'Slate',
    brandLight: Color(0xFF566476), brandDeepLight: Color(0xFF3C4756),
    brandDark: Color(0xFF9BAABC), accent: Color(0xFF7FD1E8),
  ),
  VitaScheme(
    id: 'midnight', name: 'Midnight',
    brandLight: Color(0xFF2E4B8F), brandDeepLight: Color(0xFF1E3266),
    brandDark: Color(0xFF6C90E6), accent: Color(0xFF63E6FF),
  ),
];

VitaScheme schemeById(String? id) =>
    kVitaSchemes.firstWhere((s) => s.id == id, orElse: () => kVitaSchemes.first);

/// Hue-free neutral surface bases. Each scheme tints these toward its brand so
/// the whole app — not just the accent — takes on the scheme's colour.
class _Neutral {
  const _Neutral._();
  // Light
  static const lGround = Color(0xFFF3F3F5);
  static const lCard = Color(0xFFFFFFFF);
  static const lInk = Color(0xFF17181A);
  static const lInkSoft = Color(0xFF3B3D40);
  static const lMuted = Color(0xFF6C6E73);
  static const lLine = Color(0xFFE2E2E6);
  static const lLineSoft = Color(0xFFEDEDF0);
  // Dark
  static const dGround = Color(0xFF0C0D0F);
  static const dPaper = Color(0xFF111214);
  static const dCard = Color(0xFF17181B);
  static const dInk = Color(0xFFECEDEF);
  static const dInkSoft = Color(0xFFC3C5C9);
  static const dMuted = Color(0xFF8B8D93);
  static const dLine = Color(0xFF272A2E);
  static const dLineSoft = Color(0xFF1B1D20);
}

/// Overlay [tint] onto [base] at opacity [t] — the tinting primitive used to
/// bias neutral surfaces toward a scheme's hue.
Color _mix(Color base, Color tint, double t) =>
    Color.alphaBlend(tint.withOpacity(t), base);

/// Semantic colour set resolved for the active brightness + scheme. Access via
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
    required this.accent,
  });

  final Brightness brightness;
  final Color ground; // scaffold background
  final Color paper; // inset surfaces
  final Color card; // raised cards
  final Color ink; // primary text
  final Color inkSoft; // secondary text
  final Color muted; // tertiary text / captions
  final Color line; // borders
  final Color lineSoft; // faint dividers / tracks
  final Color brand; // scheme brand resolved for brightness
  final Color brandDeep; // deeper brand for gradients
  final Color accent; // scheme hero accent (the ring highlight)

  // Data / semantic colours (constant across schemes)
  Color get ember => VitaColors.ember;
  Color get protein => VitaColors.protein;
  Color get carbs => VitaColors.carbs;
  Color get fat => VitaColors.fat;
  bool get isDark => brightness == Brightness.dark;

  /// The signature brand gradient (deep → brand → accent).
  List<Color> get brandGradient => [brandDeep, brand, accent];

  static VitaPalette light(VitaScheme s) {
    final t = s.brandLight; // tint hue for light surfaces
    return VitaPalette(
      brightness: Brightness.light,
      ground: _mix(_Neutral.lGround, t, 0.055),
      paper: _mix(_Neutral.lGround, t, 0.055),
      card: _mix(_Neutral.lCard, t, 0.020),
      ink: _mix(_Neutral.lInk, t, 0.10),
      inkSoft: _mix(_Neutral.lInkSoft, t, 0.10),
      muted: _mix(_Neutral.lMuted, t, 0.12),
      line: _mix(_Neutral.lLine, t, 0.16),
      lineSoft: _mix(_Neutral.lLineSoft, t, 0.10),
      brand: s.brandLight,
      brandDeep: s.brandDeepLight,
      accent: s.accent,
    );
  }

  static VitaPalette dark(VitaScheme s) {
    final t = s.brandDark; // brighter hue reads on deep grounds
    return VitaPalette(
      brightness: Brightness.dark,
      ground: _mix(_Neutral.dGround, t, 0.08),
      paper: _mix(_Neutral.dPaper, t, 0.09),
      card: _mix(_Neutral.dCard, t, 0.11),
      ink: _mix(_Neutral.dInk, t, 0.05),
      inkSoft: _mix(_Neutral.dInkSoft, t, 0.07),
      muted: _mix(_Neutral.dMuted, t, 0.13),
      line: _mix(_Neutral.dLine, t, 0.18),
      lineSoft: _mix(_Neutral.dLineSoft, t, 0.13),
      brand: s.brandDark,
      brandDeep: s.brandLight,
      accent: s.accent,
    );
  }
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
