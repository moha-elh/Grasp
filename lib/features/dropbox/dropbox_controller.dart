import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/services/dropbox_service.dart';

/// Dropbox connection phases for screen 01 (FR-1 → FR-3).
enum DropboxPhase { checking, disconnected, connecting, scanning, connected, error }

class DropboxStatus {
  final DropboxPhase phase;
  final int? noteCount; // eligible (#flashcard) notes found on last scan
  final String? message; // error detail
  final bool scopeError; // app registered with App-folder scope, not Full

  const DropboxStatus(this.phase,
      {this.noteCount, this.message, this.scopeError = false});

  bool get isConnected =>
      phase == DropboxPhase.connected || phase == DropboxPhase.scanning;
}

final dropboxControllerProvider =
    StateNotifierProvider<DropboxController, DropboxStatus>(
  (ref) => DropboxController(ref.watch(dropboxProvider))..init(),
);

class DropboxController extends StateNotifier<DropboxStatus> {
  final DropboxService _svc;
  DropboxController(this._svc)
      : super(const DropboxStatus(DropboxPhase.checking));

  Future<void> init() async {
    try {
      state = await _svc.isConnected
          ? const DropboxStatus(DropboxPhase.connected)
          : const DropboxStatus(DropboxPhase.disconnected);
    } catch (_) {
      // e.g. secure storage unavailable (web). Treat as disconnected.
      state = const DropboxStatus(DropboxPhase.disconnected);
    }
  }

  /// One-time interactive connect, then scan for eligible notes (§9 step 1).
  Future<void> connect() async {
    state = const DropboxStatus(DropboxPhase.connecting);
    try {
      await _svc.connect();
      await scan();
    } catch (e) {
      state = DropboxStatus(DropboxPhase.error,
          message: e.toString(), scopeError: _looksLikeScopeError(e));
    }
  }

  /// Count eligible notes to confirm access. Heavy (downloads each note to
  /// check for the tag); fine as a one-off confirmation.
  /// ponytail: full download-scan; move to a server-side/metadata check if the
  /// vault grows large enough that this is slow.
  Future<void> scan() async {
    state = const DropboxStatus(DropboxPhase.scanning);
    try {
      final notes = await _svc.eligibleNotes();
      state = DropboxStatus(DropboxPhase.connected, noteCount: notes.length);
    } catch (e) {
      // A transient failure (flaky network, generation contention) must NOT
      // make the app forget it is connected and bounce back to the connect
      // screen. If the refresh token is still stored and this is not a genuine
      // scope/permission problem, stay connected and just surface the error.
      final scope = _looksLikeScopeError(e);
      var stillConnected = false;
      if (!scope) {
        try {
          stillConnected = await _svc.isConnected;
        } catch (_) {}
      }
      state = stillConnected
          ? DropboxStatus(DropboxPhase.connected, message: e.toString())
          : DropboxStatus(DropboxPhase.error,
              message: e.toString(), scopeError: scope);
    }
  }

  Future<void> disconnect() async {
    await _svc.disconnect();
    state = const DropboxStatus(DropboxPhase.disconnected);
  }

  bool _looksLikeScopeError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('scope') || s.contains('403') || s.contains('not_found');
  }
}
