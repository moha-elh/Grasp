import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// A note read from the vault. Read-only — the app never writes back (FR-4).
class VaultNote {
  final String path;
  final String content;
  const VaultNote(this.path, this.content);
}

/// Read-only Dropbox access to the Obsidian vault (FR-1..FR-5).
///
/// Uses OAuth PKCE (no client secret on-device) with an offline refresh token.
/// The Dropbox app MUST be registered with Full Dropbox scope (FR-3), or it
/// cannot see Remotely Save's app folder.
class DropboxService {
  static const _kRefreshToken = 'dropbox_refresh_token';
  final _storage = const FlutterSecureStorage();
  final http.Client _http;

  String? _accessToken;
  DateTime _accessExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  DropboxService([http.Client? client]) : _http = client ?? http.Client();

  Future<bool> get isConnected async =>
      await _storage.read(key: _kRefreshToken) != null;

  /// One-time interactive connect (§9 step 1). Opens the system browser,
  /// exchanges the code, and stores the refresh token.
  Future<void> connect() async {
    final verifier = _randomString(64);
    final challenge = base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');

    final authUrl = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': Config.dropboxAppKey,
      'response_type': 'code',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'token_access_type': 'offline',
      'redirect_uri': Config.dropboxRedirectUri,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: Config.dropboxCallbackScheme,
    );
    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw StateError('Dropbox auth returned no code');

    final resp = await _http.post(
      Uri.https('api.dropboxapi.com', '/oauth2/token'),
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': Config.dropboxAppKey,
        'code_verifier': verifier,
        'redirect_uri': Config.dropboxRedirectUri,
      },
    );
    _checkOk(resp, 'token exchange');
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    await _storage.write(key: _kRefreshToken, value: json['refresh_token'] as String);
    _setAccess(json);
  }

  Future<void> disconnect() => _storage.delete(key: _kRefreshToken);

  /// All eligible notes: everything under the scoped folder carrying the
  /// `#flashcard` tag (FR-2). Recurses subfolders.
  Future<List<VaultNote>> eligibleNotes() async {
    final paths = await _listMarkdownPaths(Config.notesFolder);
    final notes = <VaultNote>[];
    for (final p in paths) {
      final content = await downloadNote(p);
      if (content.contains(Config.flashcardTag)) {
        notes.add(VaultNote(p, content));
      }
    }
    return notes;
  }

  Future<String> downloadNote(String path) async {
    final token = await _validAccessToken();
    final resp = await _http.post(
      Uri.https('content.dropboxapi.com', '/2/files/download'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': path}),
      },
    );
    _checkOk(resp, 'download $path');
    return utf8.decode(resp.bodyBytes);
  }

  // --- internals ---

  Future<List<String>> _listMarkdownPaths(String folder) async {
    final token = await _validAccessToken();
    final paths = <String>[];
    var body = jsonEncode({'path': folder, 'recursive': true});
    var url = Uri.https('api.dropboxapi.com', '/2/files/list_folder');

    while (true) {
      final resp = await _http.post(url,
          headers: _jsonAuth(token), body: body);
      _checkOk(resp, 'list_folder');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      for (final e in (json['entries'] as List).cast<Map<String, dynamic>>()) {
        final p = e['path_lower'] as String?;
        if (e['.tag'] == 'file' && p != null && p.endsWith('.md')) {
          paths.add(e['path_display'] as String);
        }
      }
      if (json['has_more'] != true) break;
      url = Uri.https('api.dropboxapi.com', '/2/files/list_folder/continue');
      body = jsonEncode({'cursor': json['cursor']});
    }
    return paths;
  }

  Future<String> _validAccessToken() async {
    if (_accessToken != null && DateTime.now().isBefore(_accessExpiry)) {
      return _accessToken!;
    }
    final refresh = await _storage.read(key: _kRefreshToken);
    if (refresh == null) throw StateError('Dropbox not connected');
    final resp = await _http.post(
      Uri.https('api.dropboxapi.com', '/oauth2/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
        'client_id': Config.dropboxAppKey,
      },
    );
    _checkOk(resp, 'token refresh');
    _setAccess(jsonDecode(resp.body) as Map<String, dynamic>);
    return _accessToken!;
  }

  void _setAccess(Map<String, dynamic> json) {
    _accessToken = json['access_token'] as String;
    final secs = (json['expires_in'] as int?) ?? 14400;
    _accessExpiry = DateTime.now().add(Duration(seconds: secs - 60));
  }

  Map<String, String> _jsonAuth(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  void _checkOk(http.Response r, String what) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw StateError('Dropbox $what failed (${r.statusCode}): ${r.body}');
    }
  }

  String _randomString(int len) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(len, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
