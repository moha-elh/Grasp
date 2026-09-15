import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// One web search hit with a real, citable URL (the trust layer, FR-20).
class WebResult {
  final String title;
  final String url;
  final String content; // short extract the LLM authors a card from
  const WebResult(this.title, this.url, this.content);
}

/// Web search for Explore web-sourced cards. Tavily by default (OpenAI-style
/// JSON, generous free tier). Returns real results with URLs so every web card
/// carries a genuine citation rather than an LLM-hallucinated one.
class SearchService {
  final http.Client _http;
  SearchService([http.Client? client]) : _http = client ?? http.Client();

  Future<List<WebResult>> search(String query, {int maxResults = 2}) async {
    final resp = await _http.post(
      Uri.https(Config.searchBaseUrl, Config.searchPath),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': Config.searchApiKey,
        'query': query,
        'max_results': maxResults,
        'search_depth': 'basic',
      }),
    );
    if (resp.statusCode != 200) {
      throw StateError('Search failed (${resp.statusCode}): ${resp.body}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (json['results'] as List?) ?? const [];
    return results.cast<Map<String, dynamic>>().map((r) {
      return WebResult(
        r['title'] as String? ?? '',
        r['url'] as String? ?? '',
        r['content'] as String? ?? '',
      );
    }).where((r) => r.url.isNotEmpty).toList();
  }
}
