import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Spotify account/content integration. This service never provides playback
/// URLs: KRYPT's existing music-source registry remains responsible for audio.
class SpotifyService extends ChangeNotifier {
  SpotifyService._();
  static final instance = SpotifyService._();

  static const clientId = 'abb77bc3863f4f8fab60434b4a86e2f5';
  static const redirectUri = 'kryptaudio://spotify-auth';
  static const _scopes =
      'playlist-read-private playlist-read-collaborative '
      'user-library-read user-read-private';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Map<String, dynamic>? _profile;
  bool _busy = false;
  String? _error;

  bool get isConnected => _accessToken != null;
  bool get isBusy => _busy;
  String? get error => _error;
  Map<String, dynamic>? get profile => _profile;
  String? get displayName => _profile?['display_name'] as String?;
  String? get email => _profile?['email'] as String?;

  Future<void> restore() async {
    final box = Hive.box('user');
    _refreshToken = box.get('spotifyRefreshToken') as String?;
    _accessToken = box.get('spotifyAccessToken') as String?;
    final expires = box.get('spotifyExpiresAt') as int?;
    _expiresAt = expires == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expires);
    final profile = box.get('spotifyProfile');
    if (profile is Map) _profile = Map<String, dynamic>.from(profile);
    if (_refreshToken != null &&
        (_accessToken == null || _expiresAt == null || _isExpired)) {
      await _refreshAccessToken();
    }
    notifyListeners();
  }

  bool get _isExpired =>
      _expiresAt == null ||
      DateTime.now().isAfter(_expiresAt!.subtract(const Duration(minutes: 1)));

  Future<bool> beginLogin() async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final verifier = _randomString(64);
      final state = _randomString(32);
      final challenge = base64Url
          .encode(sha256.convert(utf8.encode(verifier)).bytes)
          .replaceAll('=', '');
      final box = Hive.box('user');
      await box.put('spotifyPkceVerifier', verifier);
      await box.put('spotifyOAuthState', state);
      final uri = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': _scopes,
        'code_challenge_method': 'S256',
        'code_challenge': challenge,
        'state': state,
        'show_dialog': 'true',
      });
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> handleCallback(Uri uri) async {
    if (uri.scheme != 'kryptaudio' || uri.host != 'spotify-auth') return false;
    if (uri.queryParameters['error'] != null) {
      _error = uri.queryParameters['error'];
      notifyListeners();
      return false;
    }
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final box = Hive.box('user');
    final expectedState = box.get('spotifyOAuthState') as String?;
    final verifier = box.get('spotifyPkceVerifier') as String?;
    if (code == null ||
        state == null ||
        expectedState == null ||
        verifier == null ||
        !constantTimeEquals(state, expectedState)) {
      _error = 'Spotify sign-in could not be verified.';
      notifyListeners();
      return false;
    }
    _busy = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.https('accounts.spotify.com', '/api/token'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Spotify token exchange failed (${response.statusCode})',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(data);
      await box.delete('spotifyPkceVerifier');
      await box.delete('spotifyOAuthState');
      await loadProfile();
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _profile = null;
    final box = Hive.box('user');
    for (final key in [
      'spotifyAccessToken',
      'spotifyRefreshToken',
      'spotifyExpiresAt',
      'spotifyProfile',
      'spotifyPkceVerifier',
      'spotifyOAuthState',
    ]) {
      await box.delete(key);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> loadProfile() async {
    final data = await _getJson('/v1/me');
    _profile = data;
    await Hive.box('user').put('spotifyProfile', data);
    notifyListeners();
    return data;
  }

  Future<List<Map<String, dynamic>>> loadPlaylists() async {
    final result = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final data = await _getJson(
        '/v1/me/playlists',
        query: {'limit': '50', 'offset': '$offset'},
      );
      for (final item in (data['items'] as List? ?? const [])) {
        if (item is Map) result.add(Map<String, dynamic>.from(item));
      }
      final total = (data['total'] as num?)?.toInt() ?? result.length;
      offset += 50;
      if (offset >= total || (data['items'] as List? ?? []).isEmpty) break;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> loadLikedSongs() async {
    final result = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final data = await _getJson(
        '/v1/me/tracks',
        query: {'limit': '50', 'offset': '$offset'},
      );
      for (final item in (data['items'] as List? ?? const [])) {
        if (item is Map) result.add(Map<String, dynamic>.from(item));
      }
      final total = (data['total'] as num?)?.toInt() ?? result.length;
      offset += 50;
      if (offset >= total || (data['items'] as List? ?? []).isEmpty) break;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> loadPlaylistTracks(
    String playlistId,
  ) async {
    final result = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final data = await _getJson(
        '/v1/playlists/$playlistId/items',
        query: {
          'limit': '50',
          'offset': '$offset',
          'fields':
              'items(item(id,name,artists(name),album(name,images))),total',
        },
      );
      for (final item in (data['items'] as List? ?? const [])) {
        if (item is Map) result.add(Map<String, dynamic>.from(item));
      }
      final total = (data['total'] as num?)?.toInt() ?? result.length;
      offset += 50;
      if (offset >= total || (data['items'] as List? ?? []).isEmpty) break;
    }
    return result;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    await _ensureToken();
    final response = await http.get(
      Uri.https('api.spotify.com', path, query),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 401 && _refreshToken != null) {
      await _refreshAccessToken();
      return _getJson(path, query: query);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body.trim();
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] is Map) {
          final error = Map<String, dynamic>.from(body['error'] as Map);
          detail = error['message']?.toString() ?? detail;
          final reason = error['reason']?.toString();
          if (reason != null && reason.isNotEmpty) detail = '$detail ($reason)';
        }
      } catch (_) {
        // Keep the raw response when Spotify returns a non-JSON error body.
      }
      throw Exception(
        'Spotify API error ${response.statusCode}: ${detail.isEmpty ? 'Unknown error' : detail}',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> _ensureToken() async {
    if (_accessToken == null) throw Exception('Connect Spotify first.');
    if (_isExpired) await _refreshAccessToken();
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) return;
    final response = await http.post(
      Uri.https('accounts.spotify.com', '/api/token'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
      },
    );
    if (response.statusCode != 200) {
      await disconnect();
      throw Exception('Spotify session expired. Please connect again.');
    }
    await _saveTokens(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'] as String?;
    _refreshToken = (data['refresh_token'] as String?) ?? _refreshToken;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    final box = Hive.box('user');
    await box.put('spotifyAccessToken', _accessToken);
    await box.put('spotifyRefreshToken', _refreshToken);
    await box.put('spotifyExpiresAt', _expiresAt!.millisecondsSinceEpoch);
  }

  static String _randomString(int length) {
    final random = Random.secure();
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
      length,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
