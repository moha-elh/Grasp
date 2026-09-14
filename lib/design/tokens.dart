import 'package:flutter/widgets.dart';

/// Grasp design tokens — the porcelain palette + scales from the design system
/// (docs/Grasp Design System.dc.html). Light mode only in v1. oklch values were
/// precomputed to sRGB. Do not hardcode colors/spacing elsewhere — use these.
class T {
  T._();

  // === Color: neutrals ===
  static const ground = Color(0xFFECEEF1); // app background
  static const surface = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceSunk = Color(0xFFE5E8EC); // tab bar, card stack layers
  static const ink = Color(0xFF141A22); // primary text, primary button

  /// Ink alphas — body .72, meta .60 (never below .58), hairline .12.
  static const inkBody = Color(0xB8141A22); // .72
  static const inkMeta = Color(0x99141A22); // .60
  static const inkMetaMin = Color(0x94141A22); // .58 floor for meta text
  static const hairline = Color(0x1F141A22); // .12

  // === Color: brand accent (also means "solid") ===
  static const accent = Color(0xFF0077BD); // oklch(.55 .14 245)
  static const accentDark = Color(0xFF0068AD); // links hover, headings
  static const bead = Color(0xFF1F86CD); // recall bead sample

  // === Color: retention health — full opacity only, never decorative ===
  static const solid = accent; // retrievability >= 80%
  static const softening = Color(0xFFC26E12); // 50–79%   oklch(.62 .14 60)
  static const slipping = Color(0xFFC74B47); // < 50% and Again  oklch(.58 .16 25)
  static const again = Color(0xFFD55753); // Again grading chip fill

  // === Dual ring (screen 08) — one distinct color per arc ===
  static const ringName = accent; // outer arc: anchor / "can name" (blue)
  static const ringExplain = Color(0xFFC26E12); // inner arc: mechanism — oklch(.62 .14 60) amber

  // === Card-type badge colors (outline only) ===
  static const mechText = Color(0xFF005998);
  static const mechBorder = Color(0x733786C3); // .45 alpha
  static const appText = Color(0xFF2F6D34);
  static const appBorder = Color(0x73539156);
  static const remakeText = Color(0xFFA12F2F);
  static const remakeBorder = Color(0x73CD605A);

  // === Spacing: 4 · 8 · 12 · 18 · 24 · 32 (nothing between 12 and 18) ===
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s18 = 18.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const gutter = 24.0; // screen side gutter (24–26)
  static const sectionGap = 20.0;

  // === Radius: one per role, no mixing within a screen ===
  static const rCard = 22.0;
  static const rControl = 16.0;
  static const rPill = 999.0;
  static const rBadge = 4.0;

  // === Hit targets ===
  static const hitChip = 64.0; // grading chips
  static const hitButton = 52.0; // primary buttons
  static const hitTab = 48.0; // tab items
  static const hitMin = 44.0; // nothing tappable below this

  // === Elevation: exactly one shadow, on the active card only ===
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1F141A22), blurRadius: 40, offset: Offset(0, 20)),
  ];

  // === Motion ===
  static const mReveal = Duration(milliseconds: 180); // answer reveal, ease-out
  static const mAdvance = Duration(milliseconds: 240); // card advance
  static const mChart = Duration(milliseconds: 600); // ring/curve entry, once
  static const swipeMaxTiltDeg = 12.0;

  /// Retention health color from FSRS retrievability (0..1). §07 Data to UI.
  static Color health(double retrievability) {
    if (retrievability >= 0.80) return solid;
    if (retrievability >= 0.50) return softening;
    return slipping;
  }
}
