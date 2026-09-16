import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import 'dropbox_controller.dart';
import 'widgets/dropbox_logo.dart';

/// Screen 01 · Dropbox connect (FR-1 to FR-3). A clean, full-bleed accent
/// onboarding: the Dropbox logo, one line of why, one button.
class DropboxConnectScreen extends ConsumerWidget {
  const DropboxConnectScreen({super.key});

  static const _onAccent = Color(0xFFFFFFFF);
  static const _onAccentDim = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dropboxControllerProvider);
    final ctrl = ref.read(dropboxControllerProvider.notifier);
    final busy = status.phase == DropboxPhase.connecting ||
        status.phase == DropboxPhase.scanning;

    return Scaffold(
      backgroundColor: T.accent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s24, T.gutter, T.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(T.rCard),
                  ),
                  alignment: Alignment.center,
                  child: const DropboxLogo(size: 56),
                ),
              ),
              const SizedBox(height: T.s32),
              Text('GRASP',
                  textAlign: TextAlign.center,
                  style: Typo.mono(size: 11, color: _onAccentDim)),
              const SizedBox(height: T.s12),
              Text('Connect your vault',
                  textAlign: TextAlign.center,
                  style: Typo.display(36).copyWith(color: _onAccent)),
              const SizedBox(height: T.s18),
              Text(
                'Grasp turns the notes you tag ${Config.flashcardTag} into '
                'spaced-repetition cards. It only reads, never writes.',
                textAlign: TextAlign.center,
                style: Typo.body.copyWith(color: _onAccentDim, height: 1.5),
              ),
              const Spacer(flex: 3),
              if (status.phase == DropboxPhase.error) _errorNote(status),
              _button(busy ? _busyLabel(status.phase) : 'Connect Dropbox',
                  busy: busy, onTap: busy ? null : ctrl.connect),
              const SizedBox(height: T.s12),
              Text(
                'Full access is required: your vault lives inside another app’s '
                'folder that app-folder access can’t reach.',
                textAlign: TextAlign.center,
                style: Typo.meta.copyWith(color: _onAccentDim),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _busyLabel(DropboxPhase p) =>
      p == DropboxPhase.scanning ? 'Scanning your vault' : 'Opening Dropbox';

  // White pill on the accent ground.
  Widget _button(String label, {required bool busy, VoidCallback? onTap}) =>
      SizedBox(
        height: T.hitButton,
        child: Material(
          color: T.surface,
          borderRadius: BorderRadius.circular(T.rControl),
          child: InkWell(
            borderRadius: BorderRadius.circular(T.rControl),
            onTap: onTap,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: T.accent))
                  : Text(label,
                      style: Typo.label.copyWith(color: T.accent, fontSize: 15)),
            ),
          ),
        ),
      );

  Widget _errorNote(DropboxStatus status) {
    final text = status.scopeError
        ? 'Couldn’t read the vault. Register the Dropbox app with Full Dropbox '
            'access, not App-folder.'
        : 'Couldn’t connect. Check your connection and try again.';
    return Container(
      margin: const EdgeInsets.only(bottom: T.s18),
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
      ),
      child: Text(text, textAlign: TextAlign.center,
          style: Typo.bodySmall.copyWith(color: T.slipping)),
    );
  }
}
