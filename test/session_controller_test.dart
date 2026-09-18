import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/repositories/cards_repository.dart';
import 'package:grasp/data/repositories/reviews_repository.dart';
import 'package:grasp/data/services/fsrs_service.dart';
import 'package:grasp/features/review/session_controller.dart';
import 'package:grasp/features/session/daily_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GraspCard _card(String id, {int reps = 0}) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.approved,
    fsrs: FsrsService().newCard(),
    reps: reps,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCardsRepo extends CardsRepository {
  _FakeCardsRepo()
      : super(SupabaseClient('https://x.supabase.co', 'dummy-anon-key'));

  final List<GraspCard> newQueue = [];

  @override
  Future<List<GraspCard>> dueCards() async => [];

  @override
  Future<List<GraspCard>> newCards({required int limit}) async =>
      newQueue.take(limit).toList();

  @override
  Future<void> setQuality(String cardId, Quality quality) async {}

  @override
  Future<void> setStatus(String cardId, CardStatus status) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('flagging a brand-new card counts it against the daily allotment', () async {
    final daily = DailyController();
    await daily.ready;

    final repo = _FakeCardsRepo()..newQueue.add(_card('new'));
    final session = SessionController(
      cards: repo,
      reviews: ReviewsRepository(
          SupabaseClient('https://x.supabase.co', 'dummy-anon-key')),
      fsrs: FsrsService(),
      perDay: 10,
      daily: daily,
    );
    await pumpEventQueue();

    session.flag();
    await pumpEventQueue();

    expect(daily.remainingNewToday(10), 9,
        reason: 'a flagged new card consumes its allotment slot');
  });

  test('flagging an already-reviewed card leaves the allotment untouched', () async {
    final daily = DailyController();
    await daily.ready;

    final repo = _FakeCardsRepo()..newQueue.add(_card('seen', reps: 2));
    final session = SessionController(
      cards: repo,
      reviews: ReviewsRepository(
          SupabaseClient('https://x.supabase.co', 'dummy-anon-key')),
      fsrs: FsrsService(),
      perDay: 10,
      daily: daily,
    );
    await pumpEventQueue();

    session.flag();
    await pumpEventQueue();

    expect(daily.remainingNewToday(10), 10);
  });
}