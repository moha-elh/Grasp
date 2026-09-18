import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/features/session/daily_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new account does not inherit another account streak or intake', () async {
    SharedPreferences.setMockInitialValues({
      'user-a.streak_count': 4,
      'user-a.last_done_date': DailyController.today,
      'user-a.new_intro_count': 10,
      'user-a.new_intro_date': DailyController.today,
    });

    final fresh = DailyController(userId: 'user-b');
    await fresh.ready;

    expect(fresh.state.streak, 0);
    expect(fresh.state.lastDoneDate, isNull);
    expect(fresh.state.introducedToday, 0);
    expect(fresh.remainingNewToday(10), 10,
        reason: 'a brand-new account has its full daily new-card allotment');
  });

  test('an account restores only its own persisted progress', () async {
    SharedPreferences.setMockInitialValues({
      'user-a.streak_count': 4,
      'user-a.last_done_date': DailyController.today,
      'user-a.new_intro_count': 7,
      'user-a.new_intro_date': DailyController.today,
    });

    final a = DailyController(userId: 'user-a');
    await a.ready;

    expect(a.state.streak, 4);
    expect(a.state.doneOn(DailyController.today), isTrue);
    expect(a.remainingNewToday(10), 3);
  });
}