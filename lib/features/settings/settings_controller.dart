import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';

/// Daily NEW-card intake throttle (FR-17). The only session-sizing knob - due
/// reviews are never capped. Persisted to shared_preferences so the knob
/// survives app launches.
final newCardsPerDayProvider =
    StateNotifierProvider<NewCardsPerDayNotifier, int>(
        (_) => NewCardsPerDayNotifier());

class NewCardsPerDayNotifier extends StateNotifier<int> {
  static const _key = 'new_cards_per_day';
  static const _min = 5;
  static const _max = 30;

  NewCardsPerDayNotifier() : super(Config.defaultNewCardsPerDay) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    if (saved != null) state = saved.clamp(_min, _max);
  }

  Future<void> set(int value) async {
    state = value.clamp(_min, _max);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, state);
  }
}
