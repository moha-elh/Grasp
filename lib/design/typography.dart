import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Type roles from the design system §02. Fugaz One for the wordmark, screen
/// titles and headline numbers ONLY (one weight, never running text, never
/// below 13 or above 56). Work Sans for everything else. IBM Plex Mono for
/// small structural labels and intervals.
class Typo {
  Typo._();

  /// Screen title / big number. Size 24–40, line-height 1.1.
  static TextStyle display(double size) => GoogleFonts.fugazOne(
        fontSize: size.clamp(13, 56),
        height: 1.1,
        color: T.ink,
      );

  /// Concept name. Work Sans 600 · 19 / 1.2.
  static TextStyle conceptName = GoogleFonts.workSans(
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: T.ink,
  );

  /// Card answer. Work Sans 400 · 22 / 1.45 (min 20).
  static TextStyle answer = GoogleFonts.workSans(
    fontSize: 22,
    height: 1.45,
    color: T.ink,
  );

  /// Question / body. Work Sans 400 · 17 / 1.45 (body min 15).
  static TextStyle body = GoogleFonts.workSans(
    fontSize: 17,
    height: 1.45,
    color: T.inkBody,
  );

  static TextStyle bodySmall = GoogleFonts.workSans(
    fontSize: 15,
    height: 1.6,
    color: T.inkBody,
  );

  /// Meta text — never below .58 opacity.
  static TextStyle meta = GoogleFonts.workSans(
    fontSize: 13,
    height: 1.5,
    color: T.inkMeta,
  );

  /// Mono structural label / interval. Plex Mono 500 · 10 / .12em (min 10).
  static TextStyle mono({double size = 10, Color? color}) => GoogleFonts.ibmPlexMono(
        fontSize: size < 10 ? 10 : size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.12 * size,
        color: color ?? T.inkMeta,
      );

  /// Tappable label — minimum 14.
  static TextStyle label = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: T.ink,
  );
}
