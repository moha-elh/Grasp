import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/services/llm_service.dart';

void main() {
  test('per-minute 429 waits as long as Groq says, plus slack', () {
    expect(LlmService.rateLimitWait('on tokens per minute (TPM): Please try again in 7.5s.'),
        const Duration(milliseconds: 8500));
    expect(LlmService.rateLimitWait('(RPM): Please try again in 450ms.'),
        const Duration(milliseconds: 1450));
    expect(LlmService.rateLimitWait('Please try again in 0m30s.'),
        const Duration(seconds: 31));
    expect(LlmService.rateLimitWait('LLM failed (429): no hint'),
        const Duration(seconds: 20));
  });

  test('daily limits and long waits are not retried', () {
    expect(LlmService.rateLimitWait('on tokens per day (TPD): try again in 5m2s'), isNull);
    expect(LlmService.rateLimitWait('Please try again in 2m10s.'), isNull);
  });

  test('malformed model replies are skipped, never thrown', () {
    expect(LlmService.parseCards('not json'), isEmpty);
    expect(LlmService.parseCards('{"oops": 1}'), isEmpty);
    expect(LlmService.parseCards('[1,2]'), isEmpty);
    final cards = LlmService.parseCards('```json\n{"cards": ['
        '{"front": "q", "back": "a", "type": "anchor", "quote": 3},'
        '{"front": null, "back": "a"}, {"front": "", "back": "a"}, "junk",'
        '{"front": "q2", "back": "a2", "type": "weird"}]}```');
    expect(cards.map((c) => c.front), ['q', 'q2']);
    expect(cards[0].sourceQuote, isNull);
    expect(cards[1].type, CardType.mechanism);
  });
}
