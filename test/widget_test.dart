import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grasp/data/models/card.dart';
import 'package:grasp/design/theme.dart';
import 'package:grasp/features/shell/app_shell.dart';
import 'package:grasp/features/vetting/vetting_controller.dart';

GraspCard _pending(String id) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.pending,
    fsrs: const {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('shell boots into an active session (vetting first, tabs hidden)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Seed the vetting queue so the shell doesn't touch Supabase in tests.
        overrides: [
          vettingControllerProvider.overrideWith(
              (ref) => VettingController.seeded([_pending('a'), _pending('b')])),
        ],
        child: MaterialApp(theme: buildGraspTheme(), home: const AppShell()),
      ),
    );
    await tester.pump();

    // Vetting is woven in first (FR-15): the swipe batch and its actions show…
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    // …and the tab bar is hidden while the session is active (§14).
    expect(find.text('Retention'), findsNothing);
    expect(find.text('Explore'), findsNothing);
  });
}
