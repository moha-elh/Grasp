import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card.dart';

/// Temporary in-memory session queue so the review loop is testable before
/// Supabase/auth land. Replace this provider with a CardsRepository-backed
/// query (dueCards + newCards) once sign-in exists — the UI won't change.
final sessionQueueProvider = Provider<List<GraspCard>>((_) => _mockCards);

/// Seeds a review-state FSRS card so the recall bead shows a plausible
/// retrievability: smaller stability / more days elapsed = lower recall.
Map<String, dynamic> _fsrs({required double stability, required int daysAgo}) {
  final now = DateTime.now().toUtc();
  return {
    'cardId': now.microsecondsSinceEpoch,
    'state': 2, // review
    'step': null,
    'stability': stability,
    'difficulty': 5.0,
    'due': now.toIso8601String(),
    'lastReview': now.subtract(Duration(days: daysAgo)).toIso8601String(),
  };
}

GraspCard _card({
  required String id,
  required String front,
  required String back,
  required CardType type,
  required String note,
  required String excerpt,
  required double stability,
  required int daysAgo,
}) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'mock',
    front: front,
    back: back,
    cardType: type,
    source: CardSource.notes,
    sourcePath: '/6 - Main Notes/$note.md',
    sourceExcerpt: excerpt,
    status: CardStatus.approved,
    fsrs: _fsrs(stability: stability, daysAgo: daysAgo),
    due: now,
    reps: 3,
    createdAt: now,
    updatedAt: now,
  );
}

final _mockCards = <GraspCard>[
  _card(
    id: 'm1',
    front: 'Why can a Square that inherits from Rectangle produce a wrong area?',
    back: 'It overrides the setters to keep width and height equal, so the '
        'caller’s second assignment silently undoes the first.',
    type: CardType.mechanism,
    note: 'Liskov Substitution',
    excerpt: 'A Square is-a Rectangle mathematically, but substituting one for '
        'the other breaks callers that set width and height independently…',
    stability: 4,
    daysAgo: 6,
  ),
  _card(
    id: 'm2',
    front: 'What does “eventual consistency” guarantee, and what does it not?',
    back: 'It guarantees replicas converge if writes stop; it does not '
        'guarantee a read sees the latest write.',
    type: CardType.mechanism,
    note: 'Eventual Consistency',
    excerpt: 'Under eventual consistency, given no new updates, all replicas '
        'eventually return the last written value…',
    stability: 8,
    daysAgo: 6,
  ),
  _card(
    id: 'm3',
    front: 'What makes an operation idempotent?',
    back: 'Applying it more than once has the same effect as applying it once.',
    type: CardType.anchor,
    note: 'Idempotency',
    excerpt: 'An idempotent operation can be retried safely because repeats '
        'do not change the result beyond the first application…',
    stability: 30,
    daysAgo: 5,
  ),
  _card(
    id: 'm4',
    front: 'When would you reach for an idempotency key on a write endpoint?',
    back: 'When the client may retry the same request and duplicate side '
        'effects must be prevented (e.g. a payment charge).',
    type: CardType.application,
    note: 'Idempotency',
    excerpt: 'Payment APIs accept an idempotency key so a retried charge is '
        'de-duplicated server-side…',
    stability: 6,
    daysAgo: 8,
  ),
];
