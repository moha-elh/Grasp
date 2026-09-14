import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../review/session_complete_view.dart';
import '../review/session_controller.dart';
import '../review/widgets/grading_chips.dart';
import '../review/widgets/study_card.dart';
import '../vetting/vetting_controller.dart';
import '../vetting/vetting_view.dart';

/// Default launch surface (screen 02/03, FR-16). Runs one review session over
/// the queue. Tells the shell to hide the tab bar while a session is active so
/// the loop isn't interrupted (§14).
class SessionScreen extends ConsumerStatefulWidget {
  final ValueChanged<bool> onActiveChanged;
  const SessionScreen({super.key, required this.onActiveChanged});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  bool _active = false;

  void _syncActive(bool a) {
    if (a == _active) return;
    _active = a;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onActiveChanged(a);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: swipe-vet the bounded pending batch (FR-15), then reviews.
    final vet = ref.watch(vettingControllerProvider);
    if (!vet.isEmpty && !vet.isComplete) {
      _syncActive(true);
      return const VettingView();
    }

    final state = ref.watch(sessionControllerProvider);
    final ctrl = ref.read(sessionControllerProvider.notifier);
    final fsrs = ref.read(fsrsProvider);

    if (state.isEmpty) {
      _syncActive(false);
      return _emptyState();
    }
    if (state.isComplete) {
      _syncActive(false);
      return SessionCompleteView(
        reviewed: state.reviewed,
        flagged: state.flagged,
        nextDue: 'Next cards due tomorrow',
        onDone: () => widget.onActiveChanged(false),
      );
    }

    _syncActive(true);
    final card = state.current!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s18, T.gutter, T.s18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(state),
            const SizedBox(height: T.s18),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: StudyCard(
                    card: card,
                    revealed: state.revealed,
                    retrievability: fsrs.retrievability(card),
                    remaining: state.remaining,
                    onReveal: ctrl.reveal,
                    onOpenSource: () => _showSource(card),
                  ),
                ),
              ),
            ),
            if (state.revealed) ...[
              const SizedBox(height: T.s18),
              GradingChips(
                intervals: fsrs.previewIntervals(card),
                onGrade: ctrl.grade,
                onFlag: () => _flag(ctrl),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(SessionState state) {
    final pos = state.index + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Session', style: Typo.display(24)),
        Text('$pos / ${state.queue.length}', style: Typo.mono(size: 11)),
      ],
    );
  }

  void _flag(SessionController ctrl) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: T.ink,
      content: Text(
        'Flagged as badly made, not because it’s hard. Hard cards stay.',
        style: Typo.bodySmall.copyWith(color: T.surface),
      ),
      duration: const Duration(seconds: 3),
    ));
    ctrl.flag();
  }

  void _showSource(GraspCard card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: T.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rCard)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(T.gutter, 0, T.gutter, T.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SOURCE NOTE', style: Typo.mono(size: 10, color: T.accent)),
            const SizedBox(height: T.s12),
            Text(card.sourceExcerpt ?? '(no excerpt stored)', style: Typo.body),
            const SizedBox(height: T.s18),
            Text(card.sourcePath ?? '', style: Typo.meta),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing due', style: Typo.display(34)),
            const SizedBox(height: T.s12),
            Text('You’re clear for today. Come back tomorrow.', style: Typo.body),
          ],
        ),
      ),
    );
  }
}
