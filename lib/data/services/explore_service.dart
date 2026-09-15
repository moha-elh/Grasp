import '../../features/explore/explore_feed.dart';
import '../repositories/cards_repository.dart';
import 'llm_service.dart';
import 'search_service.dart';

/// Builds the Explore feed (FR-19) from what the user already studies: adjacent
/// concepts authored by the LLM, plus web-sourced cards carrying a real cited
/// URL. Seeds come from the approved deck's concepts. Web is best-effort, so a
/// missing search key or a failed query never blocks the adjacent cards.
class ExploreService {
  final CardsRepository _cards;
  final LlmService _llm;
  final SearchService _search;
  ExploreService(this._cards, this._llm, this._search);

  Future<List<ExploreItem>> candidates({int adjacent = 2, int web = 2}) async {
    final deck = await _cards.approvedDeck();
    final concepts = <String>{
      for (final c in deck)
        if (c.conceptName.isNotEmpty) c.conceptName,
    }.toList()
      ..shuffle();
    if (concepts.isEmpty) return const [];

    final items = <ExploreItem>[];
    var n = 0;

    for (final concept in concepts.take(adjacent)) {
      final card = await _llm.authorExplore(seedConcept: concept);
      if (card != null) {
        items.add(ExploreItem(
          id: 'a${n++}',
          kind: ExploreKind.adjacent,
          type: card.type,
          front: card.front,
          back: card.back,
          citation: 'Adjacent to your note · $concept',
        ));
      }
    }

    try {
      for (final concept in concepts.take(web)) {
        final results = await _search.search(concept, maxResults: 1);
        if (results.isEmpty) continue;
        final r = results.first;
        final card = await _llm.authorExplore(
            seedConcept: concept, webTitle: r.title, webContent: r.content);
        if (card == null) continue;
        items.add(ExploreItem(
          id: 'w${n++}',
          kind: ExploreKind.web,
          type: card.type,
          front: card.front,
          back: card.back,
          citation: '${_domain(r.url)} · ${r.title}',
          url: r.url,
        ));
      }
    } catch (_) {
      // Web sourcing unavailable (no search key yet, or a failed query).
      // Adjacent cards still stand on their own.
    }

    return items;
  }

  String _domain(String url) {
    final host = Uri.tryParse(url)?.host ?? url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}
