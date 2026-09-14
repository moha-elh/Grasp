import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../dropbox/dropbox_controller.dart';
import 'settings_controller.dart';

/// Screen 12 · Settings (FR-8, FR-17). The new-card throttle (with the load
/// tradeoff spelled out), a read-only reminder that due reviews are never
/// capped, Dropbox status, the generation mix, and sign-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: T.ground,
      appBar: AppBar(
        backgroundColor: T.ground,
        surfaceTintColor: Colors.transparent,
        title: Text('Settings', style: Typo.display(20)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s18, T.gutter, T.s32),
          children: [
            _section('SESSION'),
            _throttle(ref),
            const SizedBox(height: T.s12),
            _readonly('Due reviews are always served in full and never capped — '
                'retention depends on them.'),
            const SizedBox(height: T.s32),
            _section('NOTES'),
            _dropbox(ref),
            const SizedBox(height: T.s32),
            _section('GENERATION MIX'),
            _mix(),
            const SizedBox(height: T.s32),
            _section('ACCOUNT'),
            _signOut(context),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: T.s12),
        child: Text(label, style: Typo.mono(size: 10)),
      );

  Widget _throttle(WidgetRef ref) {
    final n = ref.watch(newCardsPerDayProvider);
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('New cards per day', style: Typo.body.copyWith(color: T.ink)),
            Text('$n', style: Typo.display(24)),
          ],
        ),
        Slider(
          value: n.toDouble(),
          min: 5,
          max: 30,
          divisions: 25,
          activeColor: T.accent,
          label: '$n',
          onChanged: (v) =>
              ref.read(newCardsPerDayProvider.notifier).state = v.round(),
        ),
        Text('Raising this means more new cards now — and a heavier review load '
            'in the weeks after, since every new card keeps coming back until '
            'it sticks.', style: Typo.bodySmall),
      ],
    ));
  }

  Widget _dropbox(WidgetRef ref) {
    final s = ref.watch(dropboxControllerProvider);
    final (label, color) = switch (s.phase) {
      DropboxPhase.connected || DropboxPhase.scanning => ('Connected', T.appText),
      DropboxPhase.error => ('Error', T.slipping),
      _ => ('Not connected', T.inkMeta),
    };
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dropbox', style: Typo.body.copyWith(color: T.ink)),
            Text(label, style: Typo.mono(size: 11, color: color)),
          ],
        ),
        const SizedBox(height: T.s8),
        Text(Config.notesFolder, style: Typo.meta),
        if (s.noteCount != null) ...[
          const SizedBox(height: T.s4),
          Text('${s.noteCount} tagged notes found', style: Typo.meta),
        ],
        if (s.isConnected) ...[
          const SizedBox(height: T.s12),
          GestureDetector(
            onTap: () => ref.read(dropboxControllerProvider.notifier).disconnect(),
            child: Text('Disconnect',
                style: Typo.label.copyWith(
                    color: T.slipping, decoration: TextDecoration.underline)),
          ),
        ],
      ],
    ));
  }

  /// Read-only target proportions for background generation (FR-8). The mix is
  /// mechanism-weighted — the app's goal is explaining, not just naming.
  Widget _mix() => _panel(Column(
        children: const [
          _MixRow('Anchor', 'naming / definition', 0.25),
          SizedBox(height: T.s12),
          _MixRow('Mechanism', 'why / how it works', 0.50),
          SizedBox(height: T.s12),
          _MixRow('Application', 'when to use it', 0.25),
        ],
      ));

  Widget _signOut(BuildContext context) => _panel(GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: T.ink,
          content: Text('Sign-in isn’t set up yet — it’s the last thing to wire.',
              style: Typo.bodySmall.copyWith(color: T.surface)),
        )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sign out', style: Typo.body.copyWith(color: T.ink)),
            const Icon(Icons.chevron_right, color: T.inkMeta, size: 20),
          ],
        ),
      ));

  Widget _readonly(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.s4),
        child: Text(text, style: Typo.bodySmall),
      );

  Widget _panel(Widget child) => Container(
        padding: const EdgeInsets.all(T.s18),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(T.rControl),
          border: Border.all(color: T.hairline),
        ),
        child: child,
      );
}

class _MixRow extends StatelessWidget {
  final String label;
  final String hint;
  final double frac;
  const _MixRow(this.label, this.hint, this.frac);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Typo.body.copyWith(color: T.ink, fontSize: 15)),
              Text(hint, style: Typo.meta),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(T.rPill),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: T.hairline,
              valueColor: const AlwaysStoppedAnimation(T.accent),
            ),
          ),
        ),
        const SizedBox(width: T.s12),
        Text('${(frac * 100).round()}%', style: Typo.mono(size: 11)),
      ],
    );
  }
}
