import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// Filled primary action — ink background, white label, 52 tall, radius 16.
/// Design system §03. Shows a spinner and disables itself when [busy].
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton(this.label, {super.key, this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: T.hitButton,
      width: double.infinity,
      child: Material(
        color: enabled ? T.ink : T.ink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(T.rControl),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.rControl),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: T.surface),
                  )
                : Text(label,
                    style: Typo.label.copyWith(color: T.surface, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
