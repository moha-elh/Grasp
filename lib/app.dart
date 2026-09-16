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
    // 1. Auth gate.
    if (ref.watch(currentSessionProvider) == null) {
      return const SignInScreen();
    }

    // 2. Dropbox gate.
    final status = ref.watch(dropboxControllerProvider);
    if (status.phase == DropboxPhase.checking) return const _Splash();
    if (status.isConnected) return const AppShell();

    return const DropboxConnectScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: T.ground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Transparent-background mascot, the brand mark, not boxed.
              Image.asset('Mascot.png', width: 220, height: 220),
              Text('Grasp', style: Typo.display(34)),
            ],
          ),
        ),
      );
}
