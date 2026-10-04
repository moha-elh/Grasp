import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card.dart';
import 'generation_prompt.dart';

/// A freshly authored card, not yet persisted.
class GeneratedCard {
  final String front;
  final String back;
  final CardType type;
  final String? sourceQuote; // verbatim span from the note, for highlighting
  const GeneratedCard(this.front, this.back, this.type, {this.sourceQuote});
}

/// Authors flashcards from note text (FR-6, text-only in v1 FR-5). The actual
/// LLM call lives in the `llm` Supabase Edge Function, so the API keys never
/// ship in the app; this just invokes it. The prompt (generation_prompt.dart) -
/// not this glue - is the product.
class LlmService {
  final SupabaseClient _db;
  LlmService(this._db);

  Future<List<GeneratedCard>> generate({
    required String notePath,
    required String noteContent,
    required Map<String, double> targetMix,
    int maxCards = 6,
    List<String> existingFronts = const [],
  }) async {
    final text = await _chat(
      generationSystemPrompt,
      generationUserPrompt(
        notePath: notePath,
        noteContent: noteContent,
        targetMix: targetMix,
        maxCards: maxCards,
        existingFronts: existingFronts,
      ),
    );
    return parseCards(text);
  }

  /// Author ONE Explore card (FR-19): an adjacent concept, or a card built
  /// strictly from [webContent]. Returns null if the model emits nothing usable.
  Future<GeneratedCard?> authorExplore({
    required String seedConcept,
    String? webTitle,
    String? webContent,
  }) async {
    final text = await _chat(
      exploreSystemPrompt,
      explorePrompt(
        seedConcept: seedConcept,
        webTitle: webTitle,
        webContent: webContent,
      ),
    );
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final front = json['front'];
    final back = json['back'];
    if (front is! String || back is! String || front.isEmpty || back.isEmpty) {
      return null;
    }
    return GeneratedCard(
      front,
      back,
      CardType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => CardType.mechanism),
    );
  }

  /// Name ONE topic adjacent to [concept] (a neighbour, NOT the concept itself)
  /// so Explore's web search widens to RELATED material rather than the note's
  /// own topic. Best-effort: returns null if the model gives nothing usable.
  Future<String?> relatedTopic(String concept) async {
    try {
      final text = await _chat(
        'Reply with strict JSON only, no prose: {"topic": "..."} where topic is '
        'a short name (2-5 words).',
        'Name ONE topic closely related to "$concept" that a learner studying '
        'it should explore next - a neighbour, NOT "$concept" itself.',
      );
      final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final t = (jsonDecode(cleaned) as Map<String, dynamic>)['topic'];
      return (t is String && t.trim().isNotEmpty) ? t.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Single JSON-mode chat round-trip through the `llm` Edge Function, which
  /// holds the Groq keys and does the key rotation/fallback server-side.
  /// Mobile/desktop sockets drop a long request now and then ("connection
  /// abort"), and a pass makes many of these, so retry transient failures here
  /// - the one spot every generation/Explore call routes through.
  Future<String> _chat(String system, String user) async {
    Object? lastErr;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final res = await _db.functions
            .invoke('llm', body: {'system': system, 'user': user});
        final data = res.data;
        if (data is Map && data['content'] is String) {
          return data['content'] as String;
        }
        throw StateError('LLM proxy error: ${data is Map ? data['error'] : data}');
      } on FunctionException catch (e) {
        // invoke throws this on any non-2xx; the function's real message (which
        // carries the upstream Groq status) is in details, not in String(e).
        final msg = '${e.details is Map ? (e.details['error'] ?? e.details) : e.details}';
        if (msg.contains('(429)')) {
          // Per-minute limits (free-tier TPM/RPM) clear in seconds: wait as
          // long as Groq says, then go again. Daily limits don't, so give up.
          final wait = rateLimitWait(msg);
          if (wait == null) throw StateError('Rate limited by Groq: $msg');
          lastErr = msg;
          await Future.delayed(wait);
          continue;
        }
        lastErr = msg; // 5xx / transient: another attempt is worth it
      } on StateError {
        rethrow;
      } catch (e) {
        lastErr = e; // network drop / timeout: worth another attempt
      }
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    throw StateError('LLM failed after retries: $lastErr');
  }

  /// How long to wait out a Groq 429, from its "Please try again in 1m2.5s"
  /// hint (+1s slack, 20s if absent). Null for daily limits (TPD/RPD), which
  /// no short wait clears, or for waits over a minute.
  static Duration? rateLimitWait(String msg) {
    if (RegExp(r'per day|\(TPD\)|\(RPD\)').hasMatch(msg)) return null;
    final m = RegExp(r'try again in (?:(\d+)m(?!s))?([\d.]+)(ms|s)').firstMatch(msg);
    if (m == null) return const Duration(seconds: 20);
    final secs = int.parse(m[1] ?? '0') * 60 +
        double.parse(m[2]!) / (m[3] == 'ms' ? 1000 : 1);
    if (secs > 60) return null;
    return Duration(milliseconds: ((secs + 1) * 1000).round());
  }

  /// Cards from the model's reply. A malformed reply or card is skipped, not
  /// thrown, so one bad answer can't abort a whole generation pass.
  static List<GeneratedCard> parseCards(String text) {
    // Model is told to emit strict JSON; strip stray fences defensively.
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
    Object? json;
    try {
      json = jsonDecode(cleaned);
    } on FormatException {
      return [];
    }
    final cards = json is Map ? json['cards'] : null;
    if (cards is! List) return [];
    return [
      for (final c in cards)
        if (c is Map &&
            c['front'] is String &&
            c['back'] is String &&
            (c['front'] as String).trim().isNotEmpty &&
            (c['back'] as String).trim().isNotEmpty)
          GeneratedCard(
            c['front'] as String,
            c['back'] as String,
            CardType.values.firstWhere((e) => e.name == c['type'],
                orElse: () => CardType.mechanism),
            sourceQuote: c['quote'] is String ? c['quote'] as String : null,
          ),
    ];
  }
}
