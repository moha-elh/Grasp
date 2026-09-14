import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import 'dropbox_controller.dart';
import 'widgets/dropbox_logo.dart';

/// Screen 01 · Dropbox connect (FR-1 to FR-3). An onboarding welcome: what
/// Grasp does, why it needs Dropbox, one button to connect. [onSkip] is a
/// debug-only bypass so the shell can be reached on web/dev where the mobile
/// OAuth scheme can't complete.
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
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s24, T.gutter, T.s24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Hero: the Dropbox glyph on a soft surface tile.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: BorderRadius.circular(T.rCard),
                  boxShadow: T.cardShadow,
                ),
                alignment: Alignment.center,
                child: const DropboxLogo(size: 52),
              ),
              const SizedBox(height: T.s24),
              Text('GRASP', style: Typo.mono(size: 11, color: T.accent)),
              const SizedBox(height: T.s12),
              Text('Connect your vault',
                  textAlign: TextAlign.center, style: Typo.display(34)),
              const SizedBox(height: T.s12),
              Text(
                'Grasp turns the notes you tag ${Config.flashcardTag} into '
                'spaced-repetition cards. Connect Dropbox to begin.',
                textAlign: TextAlign.center,
                style: Typo.body,
              ),
              const SizedBox(height: T.s32),
              const _Feature(Icons.sell_outlined, 'Reads only notes you tag',
                  'Nothing else in your Dropbox is touched.'),
              const _Feature(Icons.auto_awesome_outlined, 'Builds cards for you',
                  'Atomic, reconstructive cards, generated in the background.'),
              const _Feature(Icons.lock_outline, 'Read-only, always',
                  'Grasp never writes back to your vault.'),
              const Spacer(flex: 3),
              if (status.phase == DropboxPhase.scanning)
                _hint('Scanning your vault for tagged notes'),
              if (status.phase == DropboxPhase.error)
                _ErrorNote(status: status),
              _scopeNote(),
              const SizedBox(height: T.s18),
              PrimaryButton(
                busy ? _busyLabel(status.phase) : 'Connect Dropbox',
                busy: busy,
                onPressed: busy ? null : ctrl.connect,
              ),
              if (kDebugMode && onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text('Skip for now (debug)',
                      style: Typo.meta
                          .copyWith(decoration: TextDecoration.underline)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _busyLabel(DropboxPhase p) =>
      p == DropboxPhase.scanning ? 'Scanning your vault' : 'Opening Dropbox';

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: T.s12),
        child: Text(text, textAlign: TextAlign.center, style: Typo.meta),
      );

  Widget _scopeNote() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 14, color: T.inkMeta),
          const SizedBox(width: T.s8),
          Flexible(
            child: Text(
              'Full access is required: your vault lives inside another app’s '
              'folder, which app-folder access can’t reach.',
              style: Typo.meta,
            ),
          ),
        ],
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Feature(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: T.surfaceSunk,
              borderRadius: BorderRadius.circular(T.rControl),
            ),
            child: Icon(icon, size: 20, color: T.accent),
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Typo.body.copyWith(color: T.ink)),
                const SizedBox(height: 2),
                Text(body, style: Typo.meta),
              ],
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: T.s12),
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
