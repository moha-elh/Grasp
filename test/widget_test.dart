import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grasp/design/theme.dart';
import 'package:grasp/features/shell/app_shell.dart';

void main() {
  testWidgets('shell boots to the Session tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildGraspTheme(), home: const AppShell()),
    );
    // Session title (screen) + Session tab label both render.
    expect(find.text('Session'), findsWidgets);
    expect(find.text('Retention'), findsOneWidget); // tab label
    expect(find.text('Explore'), findsOneWidget); // tab label
  });
}
