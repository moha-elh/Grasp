import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design/theme.dart';
import 'design/tokens.dart';
import 'design/typography.dart';
import 'features/dropbox/dropbox_connect_screen.dart';
import 'features/dropbox/dropbox_controller.dart';
import 'features/shell/app_shell.dart';

/// Debug-only bypass of the Dropbox gate, so the shell is reachable on
/// web/dev where the mobile OAuth scheme can't complete.
final _devBypassProvider = StateProvider<bool>((_) => false);

/// Root widget. Gates on Dropbox connection (screen 01) before the shell.
/// Supabase sign-in is layered in later (deferred).
class GraspApp extends StatelessWidget {
  const GraspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grasp',
      debugShowCheckedModeBanner: false,
      theme: buildGraspTheme(),
      home: const _Gate(),
    );
  }
}

class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(_devBypassProvider)) return const AppShell();

    final status = ref.watch(dropboxControllerProvider);
    if (status.phase == DropboxPhase.checking) return const _Splash();
    if (status.isConnected) return const AppShell();

    return DropboxConnectScreen(
      onSkip: () => ref.read(_devBypassProvider.notifier).state = true,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text('GRASP', style: Typo.mono(size: 13, color: T.accent))),
      );
}
