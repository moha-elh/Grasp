import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import 'dropbox_controller.dart';

/// Screen 01 · Dropbox connect (FR-1 → FR-3). One explanation, one button.
/// [onSkip] is a debug-only bypass so the shell can be reached on web/dev
/// where the mobile OAuth scheme can't complete.
class DropboxConnectScreen extends ConsumerWidget {
  final VoidCallback? onSkip;
  const DropboxConnectScreen({super.key, this.onSkip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dropboxControllerProvider);
    final ctrl = ref.read(dropboxControllerProvider.notifier);
    final busy = status.phase == DropboxPhase.connecting ||
        status.phase == DropboxPhase.scanning;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: T.gutter, vertical: T.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GRASP', style: Typo.mono(size: 11, color: T.accent)),
              const SizedBox(height: T.s18),
              Text('Connect Dropbox', style: Typo.display(34)),
              const SizedBox(height: T.s18),
              Text(
                'Grasp reads your Obsidian vault to build cards from notes you '
                'tag ${Config.flashcardTag}. It never writes back.',
                style: Typo.body,
              ),
              const SizedBox(height: T.s12),
              _WhyFullScope(),
              const Spacer(),
              if (status.phase == DropboxPhase.scanning)
                _hint('Scanning your vault for tagged notes…'),
              if (status.phase == DropboxPhase.error)
                _ErrorNote(status: status),
              const SizedBox(height: T.s18),
              PrimaryButton(
                busy ? _busyLabel(status.phase) : 'Connect Dropbox',
                busy: busy,
                onPressed: busy ? null : ctrl.connect,
              ),
              if (kDebugMode && onSkip != null) ...[
                const SizedBox(height: T.s12),
                Center(
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text('Skip for now (debug)',
                        style: Typo.meta.copyWith(
                            decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _busyLabel(DropboxPhase p) =>
      p == DropboxPhase.scanning ? 'Scanning…' : 'Opening Dropbox…';

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: T.s8),
        child: Text(text, style: Typo.meta),
      );
}

class _WhyFullScope extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
        border: Border.all(color: T.hairline),
      ),
      child: Text(
        'Grasp asks for full Dropbox access because your vault lives inside '
        'another app’s folder (Remotely Save). App-folder access couldn’t reach it.',
        style: Typo.bodySmall,
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  final DropboxStatus status;
  const _ErrorNote({required this.status});

  @override
  Widget build(BuildContext context) {
    final text = status.scopeError
        ? 'Couldn’t read the vault. Make sure the Dropbox app is registered '
            'with Full Dropbox access, not App-folder.'
        : 'Couldn’t connect. Check your connection and try again.';
    return Container(
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
        border: Border.all(color: T.slipping),
      ),
      child: Text(text, style: Typo.bodySmall.copyWith(color: T.slipping)),
    );
  }
}
