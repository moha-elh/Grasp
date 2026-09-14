import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design/theme.dart';
import 'design/tokens.dart';
import 'design/typography.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/dropbox/dropbox_connect_screen.dart';
import 'features/dropbox/dropbox_controller.dart';
import 'features/shell/app_shell.dart';

/// Debug-only bypasses so the shell is reachable on web/dev where a real
/// account / the mobile OAuth scheme can't complete.
final _authBypassProvider = StateProvider<bool>((_) => false);
final _devBypassProvider = StateProvider<bool>((_) => false);

/// Root widget. Gates on sign-in, then Dropbox connection (screen 01), then the
/// shell.
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
    // 1. Auth gate (unless bypassed in debug).
    if (!ref.watch(_authBypassProvider)) {
      if (ref.watch(currentSessionProvider) == null) {
        return SignInScreen(
          onSkip: () => ref.read(_authBypassProvider.notifier).state = true,
        );
      }
    }

    // 2. Dropbox gate.
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
