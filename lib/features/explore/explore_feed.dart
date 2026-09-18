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

class ExploreState {
  final List<ExploreItem> items;
  final bool loading;
  final String? error;
  const ExploreState(this.items, {this.loading = false, this.error});

  bool get isEmpty => items.isEmpty;
}

/// The Explore feed (FR-19/FR-20). Loads adjacent + web-sourced candidates from
/// what the user already studies; verifying promotes one into Retention.
final exploreFeedProvider =
    StateNotifierProvider.autoDispose<ExploreController, ExploreState>(
  (ref) => ExploreController(const [], ref: ref),
);

class ExploreController extends StateNotifier<ExploreState> {
  final Ref? _ref;

  /// Repo-less (seeded) mode when [ref] is null: no loading, no persistence.
  /// Used by tests and keeps verify/dismiss pure.
  ExploreController(List<ExploreItem> feed, {Ref? ref})
      : _ref = ref,
        super(ExploreState(feed, loading: ref != null)) {
    if (ref != null) _load();
  }

  Future<void> _load() async {
    try {
      final items = await _ref!.read(exploreServiceProvider).candidates();
      if (mounted) state = ExploreState(items);
    } catch (e) {
      if (mounted) state = ExploreState(const [], error: e.toString());
    }
  }

  /// The trust gate's quick path (FR-20): a single verify promotes the card
  /// into the Retention deck as an `approved`, Explore-sourced NEW card, then
  /// removes it from the feed. Repo-less (seeded/test) mode just removes it.
  Future<void> verify(String id) async {
    final ref = _ref;
    final userId = ref?.read(userIdProvider);
    if (ref != null && userId != null) {
      final item = state.items.firstWhere((e) => e.id == id);
      try {
        await ref.read(cardsRepoProvider).insertExplore(
              userId: userId,
              front: item.front,
              back: item.back,
              type: item.type,
              referenceUrl: item.url,
              sourceExcerpt: item.citation,
              fsrs: ref.read(fsrsProvider),
            );
      } catch (_) {
        // Keep the item in the feed if the write fails; don't crash the UI.
        return;
      }
    }
    if (!mounted) return;
    _remove(id);
  }

  void dismiss(String id) => _remove(id);

  void _remove(String id) => state = ExploreState(
        [
          for (final e in state.items)
            if (e.id != id) e
        ],
        error: state.error,
      );
}
