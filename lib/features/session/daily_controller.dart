import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-day session progress: the streak of days the daily dose was finished,
/// and how many NEW cards have been introduced today (so reopening the app the
/// same day does not draw a fresh batch). Persisted to shared_preferences.
class DailyState {
  final int streak;
  final String? lastDoneDate; // yyyy-mm-dd of the last finished dose
  final String? introDate; // yyyy-mm-dd the intro count belongs to
  final int introducedToday;

  const DailyState({
    this.streak = 0,
    this.lastDoneDate,
    this.introDate,
    this.introducedToday = 0,
  });

  /// New-card allotment left for today, given the daily cap.
  int remainingNew(int perDay, String today) {
    final used = introDate == today ? introducedToday : 0;
    return (perDay - used).clamp(0, perDay);
  }

  bool doneOn(String today) => lastDoneDate == today;

  /// A missed day breaks the streak; show 0 until today's dose is finished.
  int shownStreak(String today, String yesterday) =>
      (lastDoneDate == today || lastDoneDate == yesterday) ? streak : 0;

  DailyState copyWith({
    int? streak,
    String? lastDoneDate,
    String? introDate,
    int? introducedToday,
  }) =>
      DailyState(
        streak: streak ?? this.streak,
        lastDoneDate: lastDoneDate ?? this.lastDoneDate,
        introDate: introDate ?? this.introDate,
        introducedToday: introducedToday ?? this.introducedToday,
      );
}

final dailyProgressProvider =
    StateNotifierProvider<DailyController, DailyState>((_) => DailyController());

class DailyController extends StateNotifier<DailyState> {
  static const _kStreak = 'streak_count';
  static const _kLastDone = 'last_done_date';
  static const _kIntroDate = 'new_intro_date';
  static const _kIntroCount = 'new_intro_count';

  DailyController() : super(const DailyState()) {
    _load();
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String get today => dateKey(DateTime.now());
  static String get yesterday =>
      dateKey(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = DailyState(
      streak: p.getInt(_kStreak) ?? 0,
      lastDoneDate: p.getString(_kLastDone),
      introDate: p.getString(_kIntroDate),
      introducedToday: p.getInt(_kIntroCount) ?? 0,
    );
  }

  /// Record that [n] new cards were drawn into today's dose.
  Future<void> recordIntroduced(int n) async {
    if (n <= 0) return;
    final t = today;
    final base = state.introDate == t ? state.introducedToday : 0;
    state = state.copyWith(introDate: t, introducedToday: base + n);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kIntroDate, t);
    await p.setInt(_kIntroCount, state.introducedToday);
  }

  /// Mark today's dose finished and advance the streak. Idempotent per day.
  Future<void> markCompleted() async {
    final t = today;
    if (state.lastDoneDate == t) return;
    final next = state.lastDoneDate == yesterday ? state.streak + 1 : 1;
    state = state.copyWith(streak: next, lastDoneDate: t);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kStreak, next);
    await p.setString(_kLastDone, t);
  }
}
