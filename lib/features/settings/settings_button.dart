import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import 'settings_screen.dart';

/// Opens Settings (screen 12). Shared so every tab can reach it, not just
/// Retention.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.settings_outlined, color: T.inkMeta),
        tooltip: 'Settings',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      );
}
