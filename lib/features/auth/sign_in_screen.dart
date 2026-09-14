import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import 'auth_controller.dart';

/// Sign-in / create-account (deferred "last bit", §8). Email + password against
/// Supabase. [onSkip] is a debug bypass so the shell stays reachable on web
/// before an account exists.
class SignInScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;
  const SignInScreen({super.key, this.onSkip});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false; // toggle: sign in vs create account
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pw = _password.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final auth = ref.read(authControllerProvider);
    try {
      if (_creating) {
        final res = await auth.signUp(email, pw);
        // With email confirmation on, there's no session yet.
        if (res.session == null && mounted) {
          setState(() => _notice =
              'Account created. Check your email to confirm, then sign in.');
        }
      } else {
        await auth.signIn(email, pw);
      }
      // On success the auth stream flips the gate; nothing else to do.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('GRASP', style: Typo.mono(size: 11, color: T.accent)),
              const SizedBox(height: T.s12),
              Text(_creating ? 'Create your account' : 'Welcome back',
                  style: Typo.display(32)),
              const SizedBox(height: T.s8),
              Text(
                _creating
                    ? 'One account holds your deck and review history.'
                    : 'Sign in to pick up your deck where you left off.',
                style: Typo.body,
              ),
              const SizedBox(height: T.s32),
              _field('Email', _email,
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email]),
              const SizedBox(height: T.s18),
              _field('Password', _password,
                  obscure: true, autofill: const [AutofillHints.password]),
              if (_error != null) ...[
                const SizedBox(height: T.s18),
                Text(_error!, style: Typo.bodySmall.copyWith(color: T.slipping)),
              ],
              if (_notice != null) ...[
                const SizedBox(height: T.s18),
                Text(_notice!, style: Typo.bodySmall.copyWith(color: T.appText)),
              ],
              const SizedBox(height: T.s24),
              PrimaryButton(_creating ? 'Create account' : 'Sign in',
                  busy: _busy, onPressed: _busy ? null : _submit),
              const SizedBox(height: T.s12),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _creating = !_creating;
                            _error = null;
                            _notice = null;
                          }),
                  child: Text(
                    _creating
                        ? 'Have an account? Sign in'
                        : 'New here? Create an account',
                    style: Typo.meta.copyWith(color: T.accent),
                  ),
                ),
              ),
              const Spacer(),
              if (kDebugMode && widget.onSkip != null)
                Center(
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text('Skip for now (debug)',
                        style: Typo.meta
                            .copyWith(decoration: TextDecoration.underline)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {bool obscure = false,
      TextInputType? keyboard,
      List<String>? autofill}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Typo.meta),
        const SizedBox(height: T.s8),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboard,
          autofillHints: autofill,
          style: Typo.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: T.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(T.rControl),
              borderSide: const BorderSide(color: T.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(T.rControl),
              borderSide: const BorderSide(color: T.accent),
            ),
          ),
        ),
      ],
    );
  }
}
