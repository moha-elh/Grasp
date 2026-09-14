import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/type_badge.dart';
import 'mock_explore.dart';

/// Explore tab (screen 11, FR-19/FR-20). Adjacent concepts + cited web cards,
/// each showing its source inline. A single verify promotes into Retention (the
/// quick path); the copy still points toward writing a note first (the trust gate).
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(exploreFeedProvider);
    final ctrl = ref.read(exploreFeedProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s32, T.gutter, T.s32),
        children: [
          Text('Explore', style: Typo.display(34)),
          const SizedBox(height: T.s12),
          Text('Candidates for exposure — not memory. Nothing enters Retention '
              'until you trust it. The stronger path is to dive in and write a '
              'note; the #flashcard tag flows it in on its own.',
              style: Typo.bodySmall),
          const SizedBox(height: T.s24),
          if (feed.isEmpty)
            _empty()
          else
            for (final item in feed) _card(context, item, ctrl),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, ExploreItem item, ExploreController ctrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: T.s18),
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rCard),
        border: Border.all(color: T.hairline),
        boxShadow: T.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _kindBadge(item.kind),
            const SizedBox(width: T.s8),
            TypeBadge.type(item.type),
          ]),
          const SizedBox(height: T.s18),
          Text(item.front, style: Typo.answer.copyWith(fontSize: 19, height: 1.35)),
          const SizedBox(height: T.s12),
          Text(item.back, style: Typo.body),
          const SizedBox(height: T.s18),
          _citation(item),
          const SizedBox(height: T.s18),
          Row(
            children: [
              Expanded(child: _verifyButton(() => ctrl.verify(item.id))),
              const SizedBox(width: T.s12),
              GestureDetector(
                onTap: () => ctrl.dismiss(item.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: T.s8, vertical: T.s12),
                  child: Text('Dismiss', style: Typo.label.copyWith(color: T.inkMeta)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // A visible source is mandatory (FR-19/20) — this is the trust layer.
  Widget _citation(ExploreItem item) => Container(
        padding: const EdgeInsets.all(T.s12),
        decoration: BoxDecoration(
          color: T.surfaceSunk,
          borderRadius: BorderRadius.circular(T.rControl),
        ),
        child: Row(
          children: [
            Icon(item.url != null ? Icons.link : Icons.hub_outlined,
                size: 15, color: T.inkMeta),
            const SizedBox(width: T.s8),
            Expanded(child: Text(item.citation, style: Typo.meta)),
          ],
        ),
      );

  Widget _verifyButton(VoidCallback onTap) => SizedBox(
        height: T.hitButton,
        child: Material(
          color: T.ink,
          borderRadius: BorderRadius.circular(T.rControl),
          child: InkWell(
            borderRadius: BorderRadius.circular(T.rControl),
            onTap: onTap,
            child: Center(
              child: Text('Verify → add to Retention',
                  style: Typo.label.copyWith(color: T.surface, fontSize: 14)),
            ),
          ),
        ),
      );

  Widget _kindBadge(ExploreKind kind) {
    final (label, color) = kind == ExploreKind.web
        ? ('WEB', T.accent)
        : ('ADJACENT', T.softening);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(T.rBadge),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: Typo.mono(size: 9.5, color: color).copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: T.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing to explore right now', style: Typo.display(24)),
            const SizedBox(height: T.s12),
            Text('New adjacent concepts and web-sourced cards will show up here.',
                style: Typo.body),
          ],
        ),
      );
}
