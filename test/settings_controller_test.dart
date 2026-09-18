import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('set persists and reloads the value', () async {
    SharedPreferences.setMockInitialValues({});

    final a = NewCardsPerDayNotifier();
    await a.set(22);
    expect(a.state, 22);

    // A fresh notifier picks up the persisted value after its async load.
    final b = NewCardsPerDayNotifier();
    await Future<void>.delayed(Duration.zero);
    expect(b.state, 22);
  });

  test('out-of-range values are clamped to the slider range', () async {
    SharedPreferences.setMockInitialValues({});

    final n = NewCardsPerDayNotifier();
    await n.set(999);
    expect(n.state, 30);
    await n.set(1);
    expect(n.state, 5);
  });

  test('cards per generation pass defaults to 15 and persists', () async {
    SharedPreferences.setMockInitialValues({});

    final a = CardsPerGenerationNotifier();
    expect(a.state, 15, reason: 'new accounts generate 15 cards by default');

    await a.set(24);
    expect(a.state, 24);

    final b = CardsPerGenerationNotifier();
    await Future<void>.delayed(Duration.zero);
    expect(b.state, 24);
  });

  test('cards per generation pass clamps out-of-range values', () async {
    SharedPreferences.setMockInitialValues({});

    final n = CardsPerGenerationNotifier();
    await n.set(999);
    expect(n.state, 45);
    await n.set(1);
    expect(n.state, 5);
  });
}
