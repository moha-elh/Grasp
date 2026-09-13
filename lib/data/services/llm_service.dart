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

/// Authors flashcards from note text via an LLM (FR-6, text-only in v1 FR-5).
/// Anthropic by default; swap the endpoint/body for OpenAI if only that key is
/// set. The prompt (generation_prompt.dart) — not this glue — is the product.
class LlmService {
  final http.Client _http;
  LlmService([http.Client? client]) : _http = client ?? http.Client();

  Future<List<GeneratedCard>> generate({
    required String notePath,
    required String noteContent,
    required Map<String, double> targetMix,
    int maxCards = 6,
  }) async {
    final key = Config.anthropicKey;
    if (key == null || key.isEmpty) {
      throw StateError('No ANTHROPIC_API_KEY set (see llm_service for OpenAI swap)');
    }

    final resp = await _http.post(
      Uri.https('api.anthropic.com', '/v1/messages'),
      headers: {
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-5',
        'max_tokens': 2048,
        'system': generationSystemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': generationUserPrompt(
              notePath: notePath,
              noteContent: noteContent,
              targetMix: targetMix,
              maxCards: maxCards,
            ),
          }
        ],
      }),
    );
    if (resp.statusCode != 200) {
      throw StateError('LLM generate failed (${resp.statusCode}): ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (body['content'] as List).first['text'] as String;
    return _parse(text);
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
