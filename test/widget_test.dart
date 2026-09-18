import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/services/fsrs_service.dart';
import 'package:grasp/design/theme.dart';
import 'package:grasp/features/review/session_controller.dart';
import 'package:grasp/features/session/daily_controller.dart';
import 'package:grasp/features/shell/app_shell.dart';
import 'package:grasp/features/vetting/vetting_controller.dart';

GraspCard _card(String id) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.approved,
    fsrs: FsrsService().newCard(),
    createdAt: now,
    updatedAt: now,
  );
}

/// An offstage-capable session whose queue the test can change after mount.
class _HoldableSession extends SessionController {
  _HoldableSession() : super.seeded(const []);
  void set(List<GraspCard> queue) => state = SessionState(queue: queue);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shell boots into Session with the four-tab bar (vetting is a tab)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Seed the controllers so the shell doesn't touch Supabase in tests.
        overrides: [
          dailyProgressProvider.overrideWith((ref) => DailyController()),
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

  testWidgets('an offstage active session does not trap you on another tab',
      (tester) async {
    final session = _HoldableSession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyProgressProvider.overrideWith((ref) => DailyController()),
          sessionControllerProvider.overrideWith((ref) => session),
          vettingControllerProvider
              .overrideWith((ref) => VettingController.seeded(const [])),
        ],
        child: MaterialApp(theme: buildGraspTheme(), home: const AppShell()),
      ),
    );
    await tester.pump();

    // Empty session: bar is up, so we can move to Explore.
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pump();
    expect(find.text('Explore'), findsWidgets);

    // Changing the card throttle redraws the offstage Session queue while we
    // sit on Explore; the Session screen now reports a live review.
    session.set([_card('live')]);
    await tester.pump();
    await tester.pump();

    // We are still on Explore AND can still reach the other tabs.
    expect(find.text('Retention'), findsOneWidget);
    expect(find.text('Vet'), findsOneWidget);
  });
}
