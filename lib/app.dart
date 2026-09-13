import 'package:flutter/material.dart';

/// Root widget. Theme + navigation land here once the design system is in.
/// ponytail: placeholder home — replace with the Notes/Explore tab shell.
class GraspApp extends StatelessWidget {
  const GraspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grasp',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('Grasp — foundation ready')),
      ),
    );
  }
}
