import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';

/// Daily NEW-card intake throttle (FR-17). The only session-sizing knob - due
/// reviews are never capped. In-memory for now; persist to Supabase (or
/// shared_preferences) once settings storage lands.
final newCardsPerDayProvider =
    StateProvider<int>((_) => Config.defaultNewCardsPerDay);
