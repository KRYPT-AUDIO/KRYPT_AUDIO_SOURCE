import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class SpotifyWebService {
  SpotifyWebService._();
  static final instance = SpotifyWebService._();

  static const _clientId = String.fromEnvironment('KRYPT_SPOTIFY_CLIENT_ID');
  final _redirectUri = '${Uri.base.origin}${Uri.base.path}';
  String? _accessToken;
  String? _deviceId;
  dynamic _player;
  Future<void>? _initializing;

  bool get configured => _clientId.isNotEmpty;
  bool get authenticated => _accessToken != null;
  bool get isAuthenticated => authenticated;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!configured) return;
    final query = Uri.base.queryParameters;
    final code = query['code'];
    if (code != null && code.isNotEmpty) {
      final verifier = html.window.localStorage['krypt_spotify_verifier'];
      if (verifier != null) {
        await _exchangeCode(code, verifier);
        html.window.history.replaceState(null, '', _redirectUri);
      }
    }

    _accessToken ??= html.window.localStorage['krypt_spotify_access_token'];
    if (_accessToken != null) await _loadSdk();
  }

  Future<bool> login() async {
    if (!configured) return false;
    await initialize();
    final verifier = _randomString(96);
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
    html.window.localStorage['krypt_spotify_verifier'] = verifier;
    final uri = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'scope': 'streaming user-read-email user-read-private user-modify-playback-state',
      'show_dialog': 'true',
    });
    html.window.location.assign(uri.toString());
    return true;
  }

  Future<bool> logout() async {
    _accessToken = null;
    _deviceId = null;
    html.window.localStorage.remove('krypt_spotify_access_token');
    html.window.localStorage.remove('krypt_spotify_expires_at');
    return true;
  }

  Future<void> _exchangeCode(String code, String verifier) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': verifier,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token']?.toString();
    if (_accessToken != null) {
      html.window.localStorage['krypt_spotify_access_token'] = _accessToken!;
      final expires = DateTime.now()
          .add(Duration(seconds: (data['expires_in'] as num?)?.toInt() ?? 3600))
          .millisecondsSinceEpoch
          .toString();
      html.window.localStorage['krypt_spotify_expires_at'] = expires;
    }
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    await initialize();
    if (_accessToken == null || query.trim().isEmpty) return [];
    final response = await _apiGet('/v1/search', {
      'q': query.trim(),
      'type': 'track',
      'limit': '25',
    });
    if (response == null) return [];
    final tracks = (response['tracks']?['items'] as List?) ?? const [];
    return tracks.whereType<Map>().map((item) {
      final album = item['album'] as Map? ?? const {};
      final artists = (item['artists'] as List?) ?? const [];
      final artist = artists.isNotEmpty
          ? (artists.first as Map)['name']?.toString() ?? ''
          : '';
      final images = (album['images'] as List?) ?? const [];
      final image = images.isNotEmpty
          ? (images.first as Map)['url']?.toString() ?? ''
          : '';
      return <String, dynamic>{
        'ytid': 'spotify:${item['id']}',
        'spotifyId': item['id'],
        'title': item['name'] ?? 'Unknown track',
        'artist': artist,
        'videoAuthor': artist,
        'album': album['name'] ?? '',
        'image': image,
        'lowResImage': image,
        'highResImage': image,
        'duration': ((item['duration_ms'] as num?)?.toInt() ?? 0) ~/ 1000,
        'isLive': false,
        'source': 'spotify-official',
      };
    }).toList();
  }

  Future<bool> playTrack(String spotifyTrackId) async {
    await initialize();
    if (_accessToken == null || _deviceId == null) return false;
    final response = await http.put(
      Uri.parse(
        'https://api.spotify.com/v1/me/player/play?device_id=$_deviceId',
      ),
      headers: _headers,
      body: jsonEncode({
        'uris': ['spotify:track:$spotifyTrackId'],
      }),
    );
    return response.statusCode == 204;
  }

  Future<bool> pause() async {
    await initialize();
    if (_accessToken == null || _deviceId == null) return false;
    final response = await http.put(
      Uri.parse(
        'https://api.spotify.com/v1/me/player/pause?device_id=$_deviceId',
      ),
      headers: _headers,
    );
    return response.statusCode == 204;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>?> _apiGet(
    String path,
    Map<String, String> parameters,
  ) async {
    final uri = Uri.https('api.spotify.com', path, parameters);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _loadSdk() async {
    // Spotify Web Playback SDK startup was removed because its legacy
    // dart:js_util bridge is not supported by the current Dart toolchain.
    // OAuth, library sync and search remain available; KRYPT browser audio
    // uses the first-party PHP stream bridge instead.
    return;
  }

  String _randomString(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '').substring(0, length);
  }
}
