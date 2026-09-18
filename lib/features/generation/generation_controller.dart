import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../settings/settings_controller.dart';
import '../../data/services/generation_service.dart';

final generationServiceProvider = Provider((ref) => GenerationService(
      ref.watch(dropboxProvider),
      ref.watch(llmProvider),
      ref.watch(cardsRepoProvider),
      ref.watch(coverageRepoProvider),
      ref.watch(fsrsProvider),
    ));

enum GenPhase { idle, running, done, error }

class GenStatus {
  final GenPhase phase;
  final int added; // cards added on the last completed pass
  final String? message; // error detail
  const GenStatus(this.phase, {this.added = 0, this.message});
}

final generationControllerProvider =
    StateNotifierProvider<GenerationController, GenStatus>(
  (ref) => GenerationController(ref),
);

/// Drives background generation (FR-7). Safe to call repeatedly - it no-ops
/// while a pass is running, when signed out, or when the queue is already full.
class GenerationController extends StateNotifier<GenStatus> {
  final Ref _ref;
  GenerationController(this._ref) : super(const GenStatus(GenPhase.idle));

  Future<void> runPass() async {
    if (state.phase == GenPhase.running) return;
    // Reading the user id touches Supabase; guard so an uninitialized client
    // (e.g. in widget tests) is a quiet no-op rather than a crash.
    String? userId;
    try {
      userId = _ref.read(userIdProvider);
    } catch (_) {
      return;
    }
    if (userId == null) return; // needs a signed-in account (RLS)

    state = const GenStatus(GenPhase.running);
    try {
      // Size the pass to the "Cards per pass" setting, so generating 15 by
      // default (or whatever the user picked) fills the Vet queue on purpose.
      final added = await _ref
          .read(generationServiceProvider)
          .runPass(userId: userId, cardsTotal: _ref.read(cardsPerGenerationProvider));
      state = GenStatus(GenPhase.done, added: added);
    } catch (e) {
      state = GenStatus(GenPhase.error, message: e.toString());
    }
  }
}
