import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// A shared HTTP client that does not depend on the phone's default resolver.
///
/// On some Android networks Dart's default host lookup (which asks for both
/// IPv4 and IPv6) returns "No address associated with hostname" (errno 7) - a
/// broken IPv6 answer that native apps quietly skip. We resolve every host to
/// an IPv4 address ourselves and connect to it, while dart:io still performs
/// TLS against the real hostname (the resolved [InternetAddress] carries it, so
/// SNI and certificate validation stay correct - no plaintext, no cert bypass).
///
/// Used by Supabase, Dropbox, and the LLM client so all three survive a flaky
/// resolver without any device settings.
http.Client resilientHttpClient() => IOClient(_makeHttpClient());

HttpClient _makeHttpClient() {
  final client = HttpClient();
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    final host = proxyHost ?? uri.host;
    final port = proxyPort ?? uri.port;
    final addr = await _resolve(host);
    // SecureSocket for https gives a ConnectionTask<SecureSocket>, which is a
    // ConnectionTask<Socket> (covariant); dart:io does the TLS handshake.
    return uri.scheme == 'https'
        ? SecureSocket.startConnect(addr, port)
        : Socket.startConnect(addr, port);
  };
  return client;
}

class _Entry {
  final InternetAddress addr;
  final DateTime expiry;
  const _Entry(this.addr, this.expiry);
}

final _cache = <String, _Entry>{};

Future<InternetAddress> _resolve(String host) async {
  final literal = InternetAddress.tryParse(host);
  if (literal != null) return literal; // already an IP

  final cached = _cache[host];
  if (cached != null && cached.expiry.isAfter(DateTime.now())) return cached.addr;

  // IPv4 only, so a broken AAAA/IPv6 answer can't poison the lookup. One retry.
  InternetAddress? addr;
  for (var i = 0; i < 2 && addr == null; i++) {
    addr = await _lookup(host, InternetAddressType.IPv4);
  }
  // Last resort: any family, preferring IPv4, in case IPv4-only returned none.
  addr ??= await _lookup(host, InternetAddressType.any, preferV4: true);
  if (addr == null) {
    throw SocketException('Could not resolve $host', address: null);
  }

  _cache[host] = _Entry(addr, DateTime.now().add(const Duration(minutes: 5)));
  return addr;
}

Future<InternetAddress?> _lookup(String host, InternetAddressType type,
    {bool preferV4 = false}) async {
  try {
    final addrs =
        await InternetAddress.lookup(host, type: type).timeout(const Duration(seconds: 6));
    if (addrs.isEmpty) return null;
    if (preferV4) {
      for (final a in addrs) {
        if (a.type == InternetAddressType.IPv4) return a;
      }
    }
    return addrs.first;
  } catch (_) {
    return null;
  }
}
