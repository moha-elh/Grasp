import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';

/// Where an Explore candidate comes from (FR-19). Adjacent = a semantic
/// neighbour of the user's own notes; web = new material sourced from the web.
enum ExploreKind { adjacent, web }

/// An Explore candidate for exposure (FR-19) - NOT a Retention card. It always
/// carries a visible source ([citation]); a card without one is a bug (FR-20).
class ExploreItem {
  final String id;
  final ExploreKind kind;
  final CardType type;
  final String front;
  final String back;
  final String citation; // human-readable source, always shown
  final String? url; // deep link for web-sourced items

  const ExploreItem({
    required this.id,
    required this.kind,
    required this.type,
    required this.front,
    required this.back,
    required this.citation,
    this.url,
  });
}

/// The Explore feed (Phase 1b). Mock for now; replace with adjacency (embeddings
/// over the vault) + web-sourced cited cards. Verifying promotes into Retention
/// (FR-20 quick path).
final exploreFeedProvider =
    StateNotifierProvider.autoDispose<ExploreController, List<ExploreItem>>(
  // The Explore tab is built eagerly in the shell's IndexedStack, so deps are
  // read lazily at verify-time (via ref) - reading Supabase-backed providers
  // here would crash tests/boot before the client is initialized.
  (ref) => ExploreController(_seed, ref: ref),
);

class ExploreController extends StateNotifier<List<ExploreItem>> {
  final Ref? _ref;

  ExploreController(super.feed, {Ref? ref}) : _ref = ref;

  /// The trust gate's quick path (FR-20): a single verify promotes the card
  /// into the Retention deck as an `approved`, Explore-sourced NEW card, then
  /// removes it from the feed. Repo-less (seeded/test) mode just removes it.
  Future<void> verify(String id) async {
    final ref = _ref;
    final userId = ref?.read(userIdProvider);
    if (ref != null && userId != null) {
      final item = state.firstWhere((e) => e.id == id);
      try {
        await ref.read(cardsRepoProvider).insertExplore(
              userId: userId,
              front: item.front,
              back: item.back,
              type: item.type,
              referenceUrl: item.url,
              fsrs: ref.read(fsrsProvider),
            );
      } catch (_) {
        // Keep the item in the feed if the write fails; don't crash the UI.
        return;
      }
    }
    if (!mounted) return;
    state = [
      for (final e in state)
        if (e.id != id) e
    ];
  }

  void dismiss(String id) => state = [
        for (final e in state)
          if (e.id != id) e
      ];
}

const _seed = <ExploreItem>[
  ExploreItem(
    id: 'e1',
    kind: ExploreKind.adjacent,
    type: CardType.mechanism,
    front: 'How do vector clocks detect concurrent writes?',
    back: 'Each replica keeps a per-node counter; two versions are concurrent '
        'when neither’s vector dominates the other.',
    citation: 'Adjacent to your note · Eventual Consistency',
  ),
  ExploreItem(
    id: 'e2',
    kind: ExploreKind.web,
    type: CardType.anchor,
    front: 'What is a CRDT?',
    back: 'A Conflict-free Replicated Data Type: a structure whose replicas '
        'merge deterministically without coordination.',
    citation: 'martin.kleppmann.com · “CRDTs: the hard parts”',
    url: 'https://martin.kleppmann.com/2020/07/06/crdt-hard-parts-hydra.html',
  ),
  ExploreItem(
    id: 'e3',
    kind: ExploreKind.adjacent,
    type: CardType.application,
    front: 'When would you prefer a B-tree over an LSM-tree?',
    back: 'Read-heavy workloads with in-place updates and predictable latency; '
        'LSM favours write-heavy, sequential ingestion.',
    citation: 'Adjacent to your note · B-Tree',
  ),
  ExploreItem(
    id: 'e4',
    kind: ExploreKind.web,
    type: CardType.mechanism,
    front: 'Why does Raft need a leader?',
    back: 'A single leader serializes the log so followers apply the same '
        'entries in the same order, making consensus tractable.',
    citation: 'raft.github.io · The Raft paper',
    url: 'https://raft.github.io/',
  ),
];
