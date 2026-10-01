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
  }) async {
    final text = await _chat(
      generationSystemPrompt,
      generationUserPrompt(
        notePath: notePath,
        noteContent: noteContent,
        targetMix: targetMix,
        maxCards: maxCards,
      ),
    );
    return _parse(text);
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
  /// holds the Groq keys and does the primary/fallback-key retry server-side.
  /// Mobile/desktop sockets drop a long request now and then ("connection
  /// abort"), and a pass makes many of these, so retry transient failures here
  /// - the one spot every generation/Explore call routes through.
  Future<String> _chat(String system, String user) async {
    Object? lastErr;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: 2 * attempt));
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
        final msg = e.details is Map ? (e.details['error'] ?? e.details) : e.details;
        // 429 = Groq rate limit; backoff + retry won't clear free-tier TPM in
        // seconds, so surface it plainly instead of hiding behind "unreachable".
        if ('$msg'.contains('(429)')) throw StateError('Rate limited by Groq: $msg');
        lastErr = msg; // 5xx / transient: another attempt is worth it
      } on StateError {
        rethrow;
      } catch (e) {
        lastErr = e; // network drop / timeout: worth another attempt
      }
    }
    throw StateError('LLM failed after retries: $lastErr');
  }

  List<GeneratedCard> _parse(String text) {
    // Model is told to emit strict JSON; strip stray fences defensively.
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return (json['cards'] as List).cast<Map<String, dynamic>>().map((c) {
      return GeneratedCard(
        c['front'] as String,
        c['back'] as String,
        CardType.values.firstWhere((e) => e.name == c['type'],
            orElse: () => CardType.mechanism),
        sourceQuote: c['quote'] as String?,
      );
    }).toList();
  }
}
