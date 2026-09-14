import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';

/// Temporary in-memory pending queue so swipe-vetting is testable before
/// background generation + Supabase land. Replace with a CardsRepository query
/// for `status = pending` (a bounded slice, FR-15) once generation exists —
/// the UI won't change.
final pendingQueueProvider = Provider<List<GraspCard>>((ref) {
  final fsrs = ref.watch(fsrsProvider);
  final now = DateTime.now().toUtc();

  GraspCard card({
    required String id,
    required String front,
    required String back,
    required CardType type,
    required String note,
    required String excerpt,
  }) =>
      GraspCard(
        id: id,
        userId: 'mock',
        front: front,
        back: back,
        cardType: type,
        source: CardSource.notes,
        sourcePath: '/6 - Main Notes/$note.md',
        sourceExcerpt: excerpt,
        status: CardStatus.pending,
        fsrs: fsrs.newCard(), // un-scheduled — only enters FSRS once approved
        createdAt: now,
        updatedAt: now,
      );

  return [
    card(
      id: 'p1',
      front: 'What problem does a write-ahead log solve?',
      back: 'Durability across crashes: changes are appended to the log and '
          'fsynced before the data pages, so recovery can replay them.',
      type: CardType.mechanism,
      note: 'Write-Ahead Logging',
      excerpt: 'A WAL records the intended change before the change itself, so '
          'a crash mid-write can be recovered by replaying the log…',
    ),
    card(
      id: 'p2',
      front: 'What is a bloom filter?',
      back: 'A probabilistic set membership structure: no false negatives, '
          'tunable false positives, in sub-linear space.',
      type: CardType.anchor,
      note: 'Bloom Filter',
      excerpt: 'A bloom filter answers “is this element possibly in the set?” '
          'using k hash functions over a bit array…',
    ),
    card(
      id: 'p3',
      front: 'When is a bloom filter the wrong tool?',
      back: 'When you need to enumerate members, delete them, or cannot '
          'tolerate any false positive.',
      type: CardType.application,
      note: 'Bloom Filter',
      excerpt: 'Because membership is probabilistic and elements are not stored, '
          'you cannot list or remove them…',
    ),
  ];
});
