import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Assembles the light-only (v1) Grasp theme from the design tokens.
ThemeData buildGraspTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: T.accent,
    surface: T.surface,
  ).copyWith(
    primary: T.ink, // primary button is ink, per §01
    secondary: T.accent,
    error: T.slipping,
    surface: T.surface,
    onSurface: T.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: T.ground,
    splashFactory: InkRipple.splashFactory,
    textTheme: TextTheme(
      titleLarge: Typo.conceptName,
      bodyLarge: Typo.body,
      bodyMedium: Typo.bodySmall,
      labelLarge: Typo.label,
    ),
    // Hairline dividers, not shadows.
    dividerTheme: const DividerThemeData(
      color: T.hairline,
      thickness: 1,
      space: 1,
    ),
  );
}
