import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card.dart';

/// Temporary in-memory Retention deck (approved cards with review history) so
/// analytics is buildable before Supabase/auth land. Replace with a
/// CardsRepository query for `status = approved` - the analytics + UI won't
/// change. Retrievability is derived by FSRS from the seeded stability/lastReview.
final deckProvider = Provider<List<GraspCard>>((_) {
  final now = DateTime.now().toUtc();

  Map<String, dynamic> seed({required double stability, required int daysAgo}) => {
        'cardId': now.microsecondsSinceEpoch,
        'state': 2, // review
        'step': null,
        'stability': stability,
        'difficulty': 5.0,
        'due': now.toIso8601String(),
        'lastReview': now.subtract(Duration(days: daysAgo)).toIso8601String(),
      };

  GraspCard card({
    required String id,
    required String note,
    required CardType type,
    required String front,
    required String back,
    required double stability,
    required int daysAgo,
    required int reps,
    int lapses = 0,
  }) =>
      GraspCard(
        id: id,
        userId: 'mock',
        front: front,
        back: back,
        cardType: type,
        source: CardSource.notes,
        sourcePath: '/6 - Main Notes/$note.md',
        sourceExcerpt: '',
        status: CardStatus.approved,
        fsrs: seed(stability: stability, daysAgo: daysAgo),
        due: now,
        reps: reps,
        lapses: lapses,
        createdAt: now,
        updatedAt: now,
      );

  return [
    // Liskov: can name it, can't explain it - the widest name/mechanism gap.
    card(id: 'd1', note: 'Liskov Substitution', type: CardType.anchor, reps: 9,
        front: 'What does the Liskov Substitution Principle state?',
        back: 'Subtypes must be substitutable for their base type without '
            'breaking callers.', stability: 40, daysAgo: 3),
    card(id: 'd2', note: 'Liskov Substitution', type: CardType.mechanism, reps: 11, lapses: 4,
        front: 'Why can a Square subclass of Rectangle break a caller?',
        back: 'Equal-side setters undo the caller’s independent width/height '
            'assignment.', stability: 3, daysAgo: 7),

    // Idempotency: solid across the board.
    card(id: 'd3', note: 'Idempotency', type: CardType.anchor, reps: 12,
        front: 'What makes an operation idempotent?',
        back: 'Applying it many times has the same effect as applying it once.',
        stability: 60, daysAgo: 4),
    card(id: 'd4', note: 'Idempotency', type: CardType.mechanism, reps: 10,
        front: 'How does an idempotency key de-duplicate a retried write?',
        back: 'The server records the key’s first result and returns it for '
            'repeats instead of re-applying.', stability: 35, daysAgo: 5),
    card(id: 'd5', note: 'Idempotency', type: CardType.application, reps: 8,
        front: 'When do you need an idempotency key on an endpoint?',
        back: 'When clients may retry and duplicate side effects must be '
            'prevented (e.g. a charge).', stability: 20, daysAgo: 6),

    // B-Tree: shaky - both low, mechanism lower.
    card(id: 'd6', note: 'B-Tree', type: CardType.anchor, reps: 6, lapses: 1,
        front: 'What is a B-tree?',
        back: 'A balanced, high-fanout search tree keeping data sorted for '
            'logarithmic lookups, inserts, and deletes.', stability: 9, daysAgo: 8),
    card(id: 'd7', note: 'B-Tree', type: CardType.mechanism, reps: 7, lapses: 3,
        front: 'Why does a B-tree keep disk reads low?',
        back: 'High fanout makes it shallow, so few nodes (few page reads) are '
            'touched per lookup.', stability: 4, daysAgo: 9),

    // CAP: named well, mechanism a bit behind.
    card(id: 'd8', note: 'CAP Theorem', type: CardType.anchor, reps: 10,
        front: 'What three properties does the CAP theorem name?',
        back: 'Consistency, Availability, Partition tolerance.', stability: 50, daysAgo: 3),
    card(id: 'd9', note: 'CAP Theorem', type: CardType.mechanism, reps: 9, lapses: 1,
        front: 'Why must you trade C or A during a partition?',
        back: 'A partition forces a choice: refuse to answer (keep C) or answer '
            'possibly-stale (keep A).', stability: 18, daysAgo: 6),
  ];
});
