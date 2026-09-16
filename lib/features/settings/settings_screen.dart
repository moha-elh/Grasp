import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import '../dropbox/dropbox_controller.dart';
import '../generation/generation_controller.dart';
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
            _readonly('Due reviews are always served in full and never capped. '
                'Retention depends on them.'),
            const SizedBox(height: T.s32),
            _section('NOTES'),
            _dropbox(ref),
            const SizedBox(height: T.s32),
            _section('GENERATION MIX'),
            _mix(),
            const SizedBox(height: T.s32),
            _section('CONTENT'),
            _generate(ref),
            const SizedBox(height: T.s32),
            _section('ACCOUNT'),
            _signOut(context, ref),
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
              ref.read(newCardsPerDayProvider.notifier).set(v.round()),
        ),
        Text('Raising this means more new cards now, and a heavier review load '
            'in the weeks after, since every new card keeps coming back until '
            'it sticks.', style: Typo.bodySmall),
      ],
    ));
  }

  Widget _dropbox(WidgetRef ref) {
    final s = ref.watch(dropboxControllerProvider);
    final busy =
        s.phase == DropboxPhase.connecting || s.phase == DropboxPhase.scanning;
    final (label, color) = switch (s.phase) {
      DropboxPhase.connected || DropboxPhase.scanning => ('Connected', T.appText),
      DropboxPhase.connecting => ('Connecting', T.inkMeta),
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
        if (s.message != null && s.phase == DropboxPhase.error) ...[
          const SizedBox(height: T.s4),
          Text(s.message!, style: Typo.meta.copyWith(color: T.slipping)),
        ],
        const SizedBox(height: T.s12),
        if (s.isConnected)
          _ghost('Disconnect', T.slipping,
              () => ref.read(dropboxControllerProvider.notifier).disconnect())
        else
          PrimaryButton(
            busy ? 'Connecting' : 'Connect Dropbox',
            busy: busy,
            onPressed: busy
                ? null
                : () => ref.read(dropboxControllerProvider.notifier).connect(),
          ),
      ],
    ));
  }

  /// Read-only target proportions for background generation (FR-8). An even
  /// split across the three card types.
  Widget _mix() => _panel(Column(
        children: const [
          _MixRow('Anchor', 'naming / definition', 0.34),
          SizedBox(height: T.s12),
          _MixRow('Mechanism', 'why / how it works', 0.33),
          SizedBox(height: T.s12),
          _MixRow('Application', 'when to use it', 0.33),
        ],
      ));

  /// Manual trigger for a background generation pass (FR-7). Normally runs on
  /// app entry; this is here to kick it and watch the result on device.
  Widget _generate(WidgetRef ref) {
    final gen = ref.watch(generationControllerProvider);
    final running = gen.phase == GenPhase.running;
    final (label, color) = switch (gen.phase) {
      GenPhase.running => ('Generating cards from your vault', T.inkMeta),
      GenPhase.done => ('Added ${gen.added} card${gen.added == 1 ? '' : 's'} last run', T.appText),
      GenPhase.error => ('Generation failed: ${gen.message ?? ''}', T.slipping),
      GenPhase.idle => ('Reads tagged notes and builds pending cards ahead of your sessions.', T.inkMeta),
    };
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Typo.bodySmall.copyWith(color: color)),
        const SizedBox(height: T.s12),
        PrimaryButton(
          running ? 'Generating' : 'Generate cards now',
          busy: running,
          onPressed: running
              ? null
              : () => ref.read(generationControllerProvider.notifier).runPass(),
        ),
      ],
    ));
  }

  Widget _signOut(BuildContext context, WidgetRef ref) => _panel(
        // Settings is pushed on top of the gate, so after clearing the session
        // we must pop back to root for the sign-in screen to surface.
        _ghost('Sign out', T.slipping, () async {
          try {
            await ref.read(authControllerProvider).signOut();
          } catch (_) {}
          if (context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        }, icon: Icons.logout),
      );

  /// A full-width outlined action button. One shape for Disconnect and Sign out
  /// so the destructive actions read the same.
  Widget _ghost(String label, Color color, VoidCallback onTap, {IconData? icon}) =>
      SizedBox(
        height: T.hitButton,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(T.rControl)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: T.s8),
              ],
              Text(label,
                  style: Typo.label.copyWith(color: color, fontSize: 15)),
            ],
          ),
        ),
      );

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
