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
  const GeneratedCard(this.front, this.back, this.type);
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

  /// Single JSON-mode chat round-trip against the configured provider.
  Future<String> _chat(String system, String user) async {
    final resp = await _http.post(
      Uri.https(Config.llmBaseUrl, Config.llmPath),
      headers: {
        'Authorization': 'Bearer ${Config.llmKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': Config.llmModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    );
    if (resp.statusCode != 200) {
      throw StateError('LLM failed (${resp.statusCode}): ${resp.body}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['choices'][0]['message']['content'] as String;
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
      );
    }).toList();
  }
}
