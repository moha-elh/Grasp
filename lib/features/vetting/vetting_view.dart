import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import 'vetting_controller.dart';
import 'widgets/vetting_card.dart';

/// Screen 05 · Swipe vetting (FR-14, FR-15). A bounded batch: header states the
/// count, a dot row shows what remains. Right accepts, left discards, up edits;
/// the three buttons mirror the swipes. Not an infinite feed.
class VettingView extends ConsumerWidget {
  const VettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vettingControllerProvider);
    final ctrl = ref.read(vettingControllerProvider.notifier);
    final card = state.current;
    if (card == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s18, T.gutter, T.s18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(state),
            const SizedBox(height: T.s12),
            _dots(state),
            const SizedBox(height: T.s18),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: VettingCard(
                    key: ValueKey(card.id),
                    card: card,
                    onAccept: ctrl.accept,
                    onDiscard: ctrl.discard,
                    onEdit: () => _openEditor(context, card, ctrl),
                  ),
                ),
              ),
            ),
            const SizedBox(height: T.s18),
            _buttons(context, card, ctrl),
          ],
        ),
      ),
    );
  }

  Widget _header(VettingState s) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Vet ${s.total}', style: Typo.display(24)),
          Text('${s.index + 1} / ${s.total}', style: Typo.mono(size: 11)),
        ],
      );

  // Dots read well for a small batch; beyond that they overflow the row, so a
  // slim progress bar carries the same "how far through" signal.
  Widget _dots(VettingState s) {
    if (s.total > 20) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(T.rPill),
        child: LinearProgressIndicator(
          value: s.total == 0 ? 0 : s.index / s.total,
          minHeight: 6,
          backgroundColor: T.hairline,
          valueColor: const AlwaysStoppedAnimation(T.ink),
        ),
      );
    }
    return Row(
      children: List.generate(s.total, (i) {
        final done = i < s.index;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == s.index ? T.ink : (done ? T.inkMeta : T.hairline),
          ),
        );
      }),
    );
  }

  Widget _buttons(BuildContext context, GraspCard card, VettingController ctrl) {
    return Row(
      children: [
        Expanded(
          child: _outline('Discard', T.slipping, ctrl.discard),
        ),
        const SizedBox(width: T.s12),
        Expanded(
          child: _outline('Edit', T.ink, () => _openEditor(context, card, ctrl)),
        ),
        const SizedBox(width: T.s12),
        Expanded(child: PrimaryButton('Accept', onPressed: ctrl.accept)),
      ],
    );
  }

  Widget _outline(String label, Color color, VoidCallback onTap) => SizedBox(
        height: T.hitButton,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(T.rControl)),
          ),
          // scaleDown keeps "Discard" on one line in the narrow third-width slot.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                maxLines: 1,
                style: Typo.label.copyWith(color: color, fontSize: 15)),
          ),
        ),
      );

  /// Screen 06 · Wording editor (FR-14 · swipe up). Edit front/back, then accept.
  void _openEditor(BuildContext context, GraspCard card, VettingController ctrl) {
    final front = TextEditingController(text: card.front);
    final back = TextEditingController(text: card.back);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: T.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rCard)),
      ),
      builder: (sheetCtx) => Padding(
        // viewInsets = keyboard; padding.bottom = system nav bar (0 when the
        // keyboard covers it). Both keep "Save & accept" above the phone buttons.
        padding: EdgeInsets.fromLTRB(
            T.gutter,
            T.s24,
            T.gutter,
            MediaQuery.of(sheetCtx).viewInsets.bottom +
                MediaQuery.of(sheetCtx).padding.bottom +
                T.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EDIT WORDING', style: Typo.mono(size: 10, color: T.accent)),
            const SizedBox(height: T.s18),
            _field('Front', front, maxLines: 2),
            const SizedBox(height: T.s18),
            _field('Back', back, maxLines: 4),
            const SizedBox(height: T.s24),
            PrimaryButton('Save & accept', onPressed: () {
              ctrl.acceptEdited(front.text.trim(), back.text.trim());
              Navigator.of(sheetCtx).pop();
            }),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {required int maxLines}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Typo.meta),
          const SizedBox(height: T.s8),
          TextField(
            controller: c,
            maxLines: maxLines,
            style: Typo.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: T.surfaceSunk,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(T.rControl),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
}
