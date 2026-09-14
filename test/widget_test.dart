import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grasp/design/theme.dart';
import 'package:grasp/features/shell/app_shell.dart';

void main() {
  testWidgets('shell boots into an active session (study card shown, tabs hidden)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: buildGraspTheme(), home: const AppShell()),
      ),
    );
    await tester.pump();

    // Study card is on screen…
    expect(find.text('RECONSTRUCT IT ALOUD'), findsOneWidget);
    // …and the tab bar is hidden while the session is active (§14).
    expect(find.text('Retention'), findsNothing);
    expect(find.text('Explore'), findsNothing);
  });
}
