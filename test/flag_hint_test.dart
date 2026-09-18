import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/features/session/flag_hint_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flag hint is shown once, then stays seen forever', () async {
    SharedPreferences.setMockInitialValues({});

    final first = FlagHintController();
    await pumpEventQueue();
    expect(first.state, isFalse);

    await first.markSeen();
    expect(first.state, isTrue);

    // A later controller on the same device must not re-show it.
    await first.markSeen();
    expect(first.state, isTrue);
  });

  test('a previously-explained device starts with the hint already seen', () async {
    SharedPreferences.setMockInitialValues({'flag_explanation_seen': true});

    final c = FlagHintController();
    await pumpEventQueue();
    expect(c.state, isTrue);
  });
}