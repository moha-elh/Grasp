import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../remake/remake_controller.dart';
import '../review/session_controller.dart';
import '../review/widgets/grading_chips.dart';
import '../review/widgets/source_note_sheet.dart';
import '../review/widgets/study_card.dart';
import '../settings/settings_button.dart';
import 'daily_controller.dart';

/// Default launch surface (screen 02/03, FR-16). Runs the day's dose of reviews
/// (vetting lives in its own tab now). Tells the shell to hide the tab bar while
/// a review is active so the loop isn't interrupted (§14).
class SessionScreen extends ConsumerStatefulWidget {
  final ValueChanged<bool> onActiveChanged;
  const SessionScreen({super.key, required this.onActiveChanged});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  bool _active = false;
  bool _markedDone = false;

  void _syncActive(bool a) {
    if (a == _active) return;
    _active = a;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onActiveChanged(a);
    });
  }

  @override
  Widget build(BuildContext context) {
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
    if (state.isComplete) {
      _syncActive(false);
      return _done(state);
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

  /// The daily dose is finished (or there was nothing due). One rest screen,
  /// with the mascot instead of a check, plus the streak.
  Widget _done(SessionState state) {
    final daily = ref.watch(dailyProgressProvider);
    final finished = state.reviewed > 0;
    // Complete the day's dose once, when the user actually reviewed something.
    if (finished && !_markedDone) {
      _markedDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dailyProgressProvider.notifier).markCompleted();
      });
    }
    final today = DailyController.today;
    final doneToday = finished || daily.doneOn(today) ||
        (daily.introDate == today && daily.introducedToday > 0);
    final streak =
        daily.shownStreak(today, DailyController.yesterday) + (finished ? 1 : 0);

    return SafeArea(
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
                    Image.asset('Mascot.png', width: 200, height: 200),
                    Text(doneToday ? 'Done for today' : 'Nothing to review yet',
                        textAlign: TextAlign.center, style: Typo.display(32)),
                    const SizedBox(height: T.s18),
                    if (doneToday) _streakPill(streak),
                    if (finished) ...[
                      const SizedBox(height: T.s24),
                      _counts(state),
                    ],
                    const SizedBox(height: T.s18),
                    Text(
                      doneToday
                          ? 'Retention is about coming back tomorrow, not '
                              'staying now.'
                          : 'Cards appear here once you approve them in the Vet '
                              'tab.',
                      textAlign: TextAlign.center,
                      style: Typo.bodySmall.copyWith(color: T.inkMeta),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakPill(int streak) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: T.s18, vertical: T.s8),
        decoration: BoxDecoration(
          color: T.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(T.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, size: 18, color: T.accent),
            const SizedBox(width: T.s8),
            Text('$streak day${streak == 1 ? '' : 's'} streak',
                style: Typo.label.copyWith(color: T.accent, fontSize: 14)),
          ],
        ),
      );

  Widget _counts(SessionState state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stat('${state.reviewed}', 'reviewed', T.accent),
          if (state.flagged > 0) ...[
            const SizedBox(width: T.s32),
            _stat('${state.flagged}', 'to remake', T.remakeText),
          ],
        ],
      );

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Text(value, style: Typo.display(34).copyWith(color: color)),
          Text(label.toUpperCase(), style: Typo.mono(size: 10)),
        ],
      );

  void _flag(SessionController ctrl) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: T.ink,
      content: Text(
        'Flagged as badly made, not because it is hard. Hard cards stay.',
        style: Typo.bodySmall.copyWith(color: T.surface),
      ),
      duration: const Duration(seconds: 3),
    ));
    ctrl.flag();
    // The remake pile is kept alive by the Retention tab, so refresh it to pick
    // up the just-flagged card.
    ref.invalidate(remakePileProvider);
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
          padding:
              const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
          child: Column(
            children: [
              const Align(
                  alignment: Alignment.centerRight, child: SettingsButton()),
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
}
