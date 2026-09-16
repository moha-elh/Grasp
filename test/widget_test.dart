import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grasp/design/theme.dart';
import 'package:grasp/features/review/session_controller.dart';
import 'package:grasp/features/shell/app_shell.dart';
import 'package:grasp/features/vetting/vetting_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shell boots into Session with the four-tab bar (vetting is a tab)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Seed the controllers so the shell doesn't touch Supabase in tests.
        overrides: [
          sessionControllerProvider
              .overrideWith((ref) => SessionController.seeded(const [])),
          vettingControllerProvider
              .overrideWith((ref) => VettingController.seeded(const [])),
        ],
        child: MaterialApp(theme: buildGraspTheme(), home: const AppShell()),
      ),
    );
    await tester.pump();

    // Session is the launch surface; the tab bar exposes Vet as its own tab.
    expect(find.text('Session'), findsWidgets);
    expect(find.text('Vet'), findsOneWidget);
    expect(find.text('Retention'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
  });
}
