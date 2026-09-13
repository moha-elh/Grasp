import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Static app config + secrets loaded from `.env`. See spec §7, §5.1.
class Config {
  // --- Secrets (from .env) ---
  static String get supabaseUrl => _req('SUPABASE_URL');
  static String get supabaseKey => _req('SUPABASE_KEY'); // publishable key
  static String get dropboxAppKey => _req('DROPBOX_APP_KEY');

  // --- LLM: OpenAI-compatible provider (Groq default) ---
  static String get llmKey => _req('GROQ_API_KEY');
  static const llmBaseUrl = 'api.groq.com';
  static const llmPath = '/openai/v1/chat/completions';
  static const llmModel = 'llama-3.3-70b-versatile';
  // Mistral swap: MISTRAL_API_KEY, 'api.mistral.ai', '/v1/chat/completions',
  // model e.g. 'mistral-large-latest'.

  // --- Dropbox (FR-2, FR-3) ---
  /// Vault folder scoped for reading. Only notes here are considered.
  static const notesFolder = '/Applications/remotely-save/Knowledge/6 - Main Notes';

  /// Per-note opt-in tag (FR-2).
  static const flashcardTag = '#flashcard';

  /// OAuth redirect; must match the Dropbox app console + the platform scheme.
  static const dropboxRedirectUri = 'grasp://auth';
  static const dropboxCallbackScheme = 'grasp';

  // --- Session / generation defaults (FR-7, FR-17, §6) ---
  /// Daily NEW-card intake cap. Due reviews are NEVER capped.
  static const defaultNewCardsPerDay = 10;

  /// Background generation stops filling the queue once this many `pending`
  /// cards exist, so the user is never flooded (FR-7).
  static const pendingQueueTarget = 30;

  static String _req(String key) {
    final v = dotenv.maybeGet(key);
    if (v == null || v.isEmpty) {
      throw StateError('Missing required env var: $key (see .env.example)');
    }
    return v;
  }
}
