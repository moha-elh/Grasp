import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../review/session_complete_view.dart';
import '../review/session_controller.dart';
import '../review/widgets/grading_chips.dart';
import '../../design/widgets/empty_state.dart';
import '../review/widgets/source_note_sheet.dart';
import '../review/widgets/study_card.dart';
import '../settings/settings_button.dart';
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
    if (vet.loading) {
      _syncActive(false);
      return _loading();
    }
    if (vet.error != null) {
      _syncActive(false);
      return _error(vet.error!);
    }
    if (!vet.isEmpty && !vet.isComplete) {
      _syncActive(true);
      return const VettingView();
    }

    // Surface a failed grade/flag write without interrupting the loop.
    ref.listen<SessionState>(sessionControllerProvider, (prev, next) {
      if (next.writeError != null && prev?.writeError != next.writeError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: T.ink,
            content: Text(
              "Couldn't save your last review. Check your connection.",
              style: Typo.bodySmall.copyWith(color: T.surface),
            ),
            duration: const Duration(seconds: 4),
          ));
      }
    });

    final state = ref.watch(sessionControllerProvider);
    final ctrl = ref.read(sessionControllerProvider.notifier);
    final fsrs = ref.read(fsrsProvider);

    if (state.loading) {
      _syncActive(false);
      return _loading();
    }
    if (state.error != null) {
      _syncActive(false);
      return _error(state.error!);
    }
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$pos / ${state.queue.length}', style: Typo.mono(size: 11)),
            const SizedBox(width: T.s8),
            const SettingsButton(),
          ],
        ),
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
      isScrollControlled: true,
      backgroundColor: T.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rCard)),
      ),
      builder: (_) => SourceNoteSheet(card),
    );
  }

  Widget _loading() => const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _error(String message) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
          child: Column(
            children: [
              const Align(alignment: Alignment.centerRight, child: SettingsButton()),
              Expanded(
                child: Center(
                  child: Text("Couldn't load your cards.\n$message",
                      textAlign: TextAlign.center,
                      style: Typo.bodySmall.copyWith(color: T.slipping)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          children: const [
            Align(alignment: Alignment.centerRight, child: SettingsButton()),
            Expanded(
              child: EmptyState(
                icon: Icons.self_improvement_outlined,
                title: 'Nothing due',
                message: 'You’re clear for today. Come back tomorrow.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
