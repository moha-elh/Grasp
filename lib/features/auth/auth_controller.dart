import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';

/// Emits on every auth change (sign-in, sign-out, token refresh) so the gate
/// re-evaluates. supabase_flutter persists the session across launches.
final authStateChangesProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange);

/// The current session, or null when signed out. Rebuilds via the stream.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseProvider).auth.currentSession;
});

final authControllerProvider =
    Provider((ref) => AuthController(ref.watch(supabaseProvider)));

/// Thin wrapper over Supabase email/password auth (§8, single-user, RLS-scoped).
class AuthController {
  final SupabaseClient _client;
  AuthController(this._client);

  Future<void> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email.trim(), password: password);

  Future<void> signOut() => _client.auth.signOut();
}
