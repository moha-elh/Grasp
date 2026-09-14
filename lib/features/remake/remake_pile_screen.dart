import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/type_badge.dart';
import 'remake_controller.dart';

/// Screen 10 · Remake pile (FR-26). Flagged (badly-made) cards in a list with
/// one batch action to regenerate. Reached from Retention only, never surfaced
/// mid-session. Regenerated cards re-enter through vetting.
class RemakePileScreen extends ConsumerWidget {
  const RemakePileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pile = ref.watch(remakePileProvider);
    final ctrl = ref.read(remakePileProvider.notifier);

    return Scaffold(
      backgroundColor: T.ground,
      appBar: AppBar(
        backgroundColor: T.ground,
        surfaceTintColor: Colors.transparent,
        title: Text('Remake pile', style: Typo.display(20)),
      ),
      body: SafeArea(
        top: false,
        child: pile.isEmpty ? _empty() : _list(context, pile, ctrl),
      ),
    );
  }

  Widget _list(
      BuildContext context, List<GraspCard> pile, RemakePileController ctrl) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.gutter, T.s18, T.gutter, T.s18),
            children: [
              Text('Cards you flagged as badly made. Regenerate them in a batch, '
                  'or handle one at a time. The daily session is never interrupted.',
                  style: Typo.bodySmall),
              const SizedBox(height: T.s24),
              for (final c in pile) _card(c, ctrl),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s8, T.gutter, T.s24),
          child: PrimaryButton('Regenerate all (${pile.length})',
              onPressed: ctrl.regenerateAll),
        ),
      ],
    );
  }

  Widget _card(GraspCard c, RemakePileController ctrl) => Container(
        margin: const EdgeInsets.only(bottom: T.s12),
        padding: const EdgeInsets.all(T.s18),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(T.rControl),
          border: Border.all(color: T.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TypeBadge.remake(),
                Text(c.conceptName, style: Typo.meta),
              ],
            ),
            const SizedBox(height: T.s12),
            Text(c.front, style: Typo.body.copyWith(color: T.ink)),
            const SizedBox(height: T.s8),
            Text(c.back, style: Typo.bodySmall),
            const SizedBox(height: T.s18),
            Row(
              children: [
                Expanded(
                  child: _action('Keep it', Icons.check, T.appText,
                      () => ctrl.accept(c.id)),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: _action('Delete', Icons.delete_outline, T.slipping,
                      () => ctrl.delete(c.id)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) =>
      SizedBox(
        height: T.hitMin,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 17, color: color),
          label: Text(label, style: Typo.label.copyWith(color: color, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(T.rControl)),
          ),
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing to remake', style: Typo.display(28)),
            const SizedBox(height: T.s12),
            Text('Flagged cards land here for a batch fix. The pile is clear.',
                style: Typo.body),
          ],
        ),
      );
}
