import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../settings/settings_button.dart';
import 'vetting_controller.dart';
import 'vetting_view.dart';

/// The Vet tab (FR-14/FR-15). Its own surface now, visited when you like (for
/// example after the daily dose) instead of being forced ahead of reviews. Runs
/// the bounded swipe batch when there are pending cards, otherwise a calm rest
/// state.
class VettingScreen extends ConsumerWidget {
  const VettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(vettingControllerProvider);
    if (s.loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (s.error != null) {
      return _rest('Could not load cards to vet', s.error!);
    }
    if (s.isEmpty || s.isComplete) {
      return _rest('All vetted',
          'New cards land here after generation. Come back when there are more.');
    }
    return const VettingView();
  }

  Widget _rest(String title, String message) => SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s18),
          child: Column(
            children: [
              const Align(
                  alignment: Alignment.centerRight, child: SettingsButton()),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('Mascot.png', width: 160, height: 160),
                      const SizedBox(height: T.s8),
                      Text(title,
                          textAlign: TextAlign.center, style: Typo.display(26)),
                      const SizedBox(height: T.s12),
                      Text(message,
                          textAlign: TextAlign.center,
                          style: Typo.body.copyWith(color: T.inkMeta)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
