import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the "flagged = badly made, hard cards stay" explanation has already
/// been shown once on this device. The first flag surfaces it; every later
/// flag is silent so the banner never gets in the way again.
final flagHintSeenProvider =
    StateNotifierProvider<FlagHintController, bool>((_) => FlagHintController());

class FlagHintController extends StateNotifier<bool> {
  static const _key = 'flag_explanation_seen';
  FlagHintController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}