import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/repositories/cards_repository.dart';
import 'package:grasp/data/repositories/coverage_repository.dart';
import 'package:grasp/data/services/dropbox_service.dart';
import 'package:grasp/data/services/fsrs_service.dart';
import 'package:grasp/data/services/generation_service.dart';
import 'package:grasp/data/services/llm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = SupabaseClient('https://x.supabase.co', 'dummy-anon-key');

class _Dropbox extends DropboxService {
  final List<VaultNote> notes;
  _Dropbox(this.notes);
  @override
  Future<List<VaultNote>> eligibleNotes() async => notes;
}

/// In-memory cards table: front + source path per card.
class _Cards extends CardsRepository {
  _Cards({this.pending = 0}) : super(_db);
  int pending;
  final rows = <(String path, String front)>[];

  @override
  Future<int> pendingCount() async => pending + rows.length;
  @override
  Future<Map<CardType, int>> qualityBalanceByType() async =>
      {for (final t in CardType.values) t: 0};
  @override
  Future<List<String>> frontsForNote(String sourcePath, {int limit = 50}) async =>
      [for (final r in rows) if (r.$1 == sourcePath) r.$2];
  @override
  Future<void> insertGenerated({
    required String userId,
    required String sourcePath,
    required String sourceExcerpt,
    required List<GeneratedCard> cards,
    required FsrsService fsrs,
  }) async =>
      rows.addAll([for (final c in cards) (sourcePath, c.front)]);
}

class _Coverage extends CoverageRepository {
  _Coverage() : super(_db);
  @override
  Future<List<String>> nextToGenerate(List<String> eligiblePaths) async =>
      eligiblePaths;
  @override
  Future<void> markGenerated(String userId, String sourcePath, int n) async {}
}

/// Fake model: each note holds [ideas] distinct ideas. It returns up to
/// [overshoot] more than asked, repeats an already-covered idea unless the
/// prompt lists it, and can fail on a given call.
class _Llm extends LlmService {
  _Llm({this.ideas = 100, this.overshoot = 0, this.failOnCall, this.ignoreCovered = false})
      : super(_db);
  final int ideas, overshoot;
  final int? failOnCall;
  final bool ignoreCovered;
  int calls = 0;

  @override
  Future<List<GeneratedCard>> generate({
    required String notePath,
    required String noteContent,
    required Map<String, double> targetMix,
    int maxCards = 6,
    List<String> existingFronts = const [],
  }) async {
    calls++;
    if (calls == failOnCall) throw StateError('Rate limited by Groq: (429)');
    final covered = ignoreCovered ? <String>{} : existingFronts.toSet();
    return [
      for (var i = 0; i < ideas; i++)
        if (!covered.contains('$notePath q$i')) '$notePath q$i'
    ]
        .take(maxCards + overshoot)
        .map((f) => GeneratedCard(f, 'a', CardType.mechanism))
        .toList();
  }
}

GenerationService _svc(_Llm llm, _Cards cards, int notes) => GenerationService(
      _Dropbox([for (var i = 0; i < notes; i++) VaultNote('n$i', 'text')]),
      llm,
      cards,
      _Coverage(),
      FsrsService(),
    );

void main() {
  test('adds exactly the pass size even when the model overshoots', () async {
    for (final total in [5, 15, 16, 45]) {
      final cards = _Cards();
      final n = await _svc(_Llm(overshoot: 4), cards, 10)
          .runPass(userId: 'u', cardsTotal: total);
      expect(n, total);
      expect(cards.rows.length, total);
    }
  });

  test('a single tiny note is revisited without duplicates until it runs dry', () async {
    final cards = _Cards();
    final n = await _svc(_Llm(ideas: 7), cards, 1).runPass(userId: 'u', cardsTotal: 15);
    expect(n, 7, reason: 'only 7 distinct ideas exist');
    expect(cards.rows.map((r) => r.$2).toSet().length, 7);
  });

  test('exact repeats are dropped even if the model ignores the covered list', () async {
    final cards = _Cards();
    final svc = _svc(_Llm(ideas: 4, ignoreCovered: true), cards, 2);
    await svc.runPass(userId: 'u', cardsTotal: 15);
    await svc.runPass(userId: 'u', cardsTotal: 15);
    final fronts = cards.rows.map((r) => r.$2).toList();
    expect(fronts.toSet().length, fronts.length);
  });

  test('a pass that runs is not cut short by the pending cap, but a full queue skips it', () async {
    final partly = _Cards(pending: 25);
    expect(await _svc(_Llm(), partly, 5).runPass(userId: 'u', cardsTotal: 15), 15);
    final full = _Cards(pending: 30);
    expect(await _svc(_Llm(), full, 5).runPass(userId: 'u', cardsTotal: 15), 0);
  });

  test('a mid-pass failure keeps the cards already made; a first-call failure surfaces', () async {
    final cards = _Cards();
    final n = await _svc(_Llm(failOnCall: 2), cards, 5).runPass(userId: 'u', cardsTotal: 15);
    expect(n, 5);
    expect(cards.rows.length, 5);
    expect(() => _svc(_Llm(failOnCall: 1), _Cards(), 5).runPass(userId: 'u', cardsTotal: 15),
        throwsStateError);
  });

  test('an exhausted vault terminates and makes a bounded number of calls', () async {
    final llm = _Llm(ideas: 0);
    expect(await _svc(llm, _Cards(), 300).runPass(userId: 'u', cardsTotal: 15), 0);
    expect(llm.calls, lessThanOrEqualTo(15));
  });

  test('empty vault is a no-op', () async {
    expect(await _svc(_Llm(), _Cards(), 0).runPass(userId: 'u', cardsTotal: 15), 0);
  });
}
