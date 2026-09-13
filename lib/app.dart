import 'package:flutter/material.dart';

import 'design/theme.dart';
import 'features/shell/app_shell.dart';

/// Root widget. Design system theme + the Session/Retention/Explore shell.
/// Sign-in and Dropbox connect are layered in later (deferred features).
class GraspApp extends StatelessWidget {
  const GraspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grasp',
      debugShowCheckedModeBanner: false,
      theme: buildGraspTheme(),
      home: const AppShell(),
    );
  }
}
