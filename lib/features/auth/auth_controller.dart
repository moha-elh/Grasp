import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';

/// The current session, or null when signed out. Rebuilds via the auth stream
/// (authChangesProvider), which also persists across launches.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authChangesProvider);
  return ref.watch(supabaseProvider).auth.currentSession;
});

final authControllerProvider =
    Provider((ref) => AuthController(ref.watch(supabaseProvider)));

/// Thin wrapper over Supabase email/password auth (§8, single-user, RLS-scoped).
class AuthController {
  final SupabaseClient _client;
  AuthController(this._client);

  // Timeout so a stalled request surfaces an error instead of spinning forever.
  static const _timeout = Duration(seconds: 20);

  Future<void> signIn(String email, String password) => _client.auth
      .signInWithPassword(email: email.trim(), password: password)
      .timeout(_timeout);

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email.trim(), password: password).timeout(_timeout);

  Future<void> signOut() => _client.auth.signOut().timeout(_timeout);
}
