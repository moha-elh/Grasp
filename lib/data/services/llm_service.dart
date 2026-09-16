import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
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

/// Authors flashcards from note text via an OpenAI-compatible LLM API
/// (FR-6, text-only in v1 FR-5). Provider/model configured in Config (Groq
/// default; Mistral is a drop-in swap). The prompt (generation_prompt.dart) - /// not this glue - is the product.
class LlmService {
  final http.Client _http;
  LlmService([http.Client? client]) : _http = client ?? http.Client();

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

  /// Single JSON-mode chat round-trip. Tries the primary Groq key, then the
  /// optional fallback key when the primary is rate limited, rejected, or the
  /// request fails (a plain bad-request 4xx is not retried - another key won't
  /// fix it).
  Future<String> _chat(String system, String user) async {
    final keys = <String>[Config.llmKey];
    final fb = Config.llmKeyFallback;
    if (fb != null && fb.isNotEmpty && fb != Config.llmKey) keys.add(fb);

    final payload = jsonEncode({
      'model': Config.llmModel,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    Object error = StateError('LLM failed');
    for (var i = 0; i < keys.length; i++) {
      try {
        final resp = await _http.post(
          Uri.https(Config.llmBaseUrl, Config.llmPath),
          headers: {
            'Authorization': 'Bearer ${keys[i]}',
            'Content-Type': 'application/json',
          },
          body: payload,
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          return body['choices'][0]['message']['content'] as String;
        }
        error = StateError('LLM failed (${resp.statusCode}): ${resp.body}');
        final worthFallback = resp.statusCode == 429 ||
            resp.statusCode == 401 ||
            resp.statusCode == 403 ||
            resp.statusCode >= 500;
        if (!worthFallback) break;
      } catch (e) {
        error = e; // network error: worth trying the other key
      }
    }
    throw error is StateError ? error : StateError('LLM failed: $error');
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
