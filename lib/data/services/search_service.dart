import 'package:supabase_flutter/supabase_flutter.dart';

/// One web search hit with a real, citable URL (the trust layer, FR-20).
class WebResult {
  final String title;
  final String url;
  final String content; // short extract the LLM authors a card from
  const WebResult(this.title, this.url, this.content);
}

/// Web search for Explore web-sourced cards. The Tavily call lives in the
/// `search` Supabase Edge Function so the search key never ships in the app;
/// this just invokes it. Returns real results with URLs so every web card
/// carries a genuine citation rather than an LLM-hallucinated one.
class SearchService {
  final SupabaseClient _db;
  SearchService(this._db);

  Future<List<WebResult>> search(String query, {int maxResults = 2}) async {
    final res = await _db.functions
        .invoke('search', body: {'query': query, 'maxResults': maxResults});
    final data = res.data;
    final results = (data is Map ? data['results'] as List? : null) ?? const [];
    return results.cast<Map<String, dynamic>>().map((r) {
      return WebResult(
        r['title'] as String? ?? '',
        r['url'] as String? ?? '',
        r['content'] as String? ?? '',
      );
    }).where((r) => r.url.isNotEmpty).toList();
  }
}
