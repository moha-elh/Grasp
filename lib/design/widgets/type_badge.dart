import 'package:flutter/widgets.dart';

import '../../data/models/card.dart';
import '../tokens.dart';
import 'tag.dart';

/// Tinted tag for card type (FR-8) and lifecycle states. Colors match the app's
/// type scheme everywhere: Naming/anchor = blue, Mechanism = amber, Application
/// = green. Design system §04 Type badges (quiet metadata, not actions).
class TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TypeBadge._(this.label, this.color);

  factory TypeBadge.type(CardType type) => switch (type) {
        CardType.anchor => const TypeBadge._('Anchor', T.ringName),
        CardType.mechanism => const TypeBadge._('Mechanism', T.ringExplain),
        CardType.application => const TypeBadge._('Application', T.appText),
      };

  factory TypeBadge.remake() => const TypeBadge._('Remake', T.remakeText);
  factory TypeBadge.pending() => const TypeBadge._('Pending', T.inkMeta);

  @override
  Widget build(BuildContext context) => Tag(label, color);
}
