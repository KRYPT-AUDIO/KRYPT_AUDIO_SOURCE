import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebProviderService {
  static Future<List<Map<String, dynamic>>> search(String query) async {
    if (!kIsWeb || query.trim().isEmpty) return [];
    final deezer = await _searchDeezer(query);
    if (deezer.isNotEmpty) return deezer;
    return _searchItunes(query);
  }

  static Future<List<Map<String, dynamic>>> _searchDeezer(String query) async {
    try {
      final uri = Uri.https('api.deezer.com', '/search', {
        'q': query.trim(),
        'limit': '25',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is! List) return [];
      return data.whereType<Map>().map((item) {
        final artist = item['artist'] is Map ? item['artist']['name'] : '';
        final album = item['album'] is Map ? item['album'] : const {};
        final id = item['id']?.toString() ?? '';
        final image = album['cover_xl'] ?? album['cover_medium'];
        return _song(
          id: 'deezer:$id',
          title: item['title']?.toString() ?? 'Unknown track',
          artist: artist.toString(),
          image: image?.toString(),
          previewUrl: item['preview']?.toString(),
          source: 'deezer',
        );
      }).where((song) => song['previewUrl'].toString().isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _searchItunes(String query) async {
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': query.trim(),
        'media': 'music',
        'entity': 'song',
        'limit': '25',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      final results = decoded is Map ? decoded['results'] : null;
      if (results is! List) return [];
      return results.whereType<Map>().map((item) {
        final id = item['trackId']?.toString() ?? '';
        return _song(
          id: 'itunes:$id',
          title: item['trackName']?.toString() ?? 'Unknown track',
          artist: item['artistName']?.toString() ?? '',
          image: item['artworkUrl100']?.toString()?.replaceFirst('100x100', '600x600'),
          previewUrl: item['previewUrl']?.toString(),
          source: 'itunes',
        );
      }).where((song) => song['previewUrl'].toString().isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _song({
    required String id,
    required String title,
    required String artist,
    required String? image,
    required String? previewUrl,
    required String source,
  }) {
    final artwork = image ?? '';
    return {
      'ytid': id,
      'title': title,
      'artist': artist,
      'artistId': null,
      'videoAuthor': artist,
      'image': artwork,
      'lowResImage': artwork,
      'highResImage': artwork,
      'duration': 30,
      'isLive': false,
      'source': source,
      'previewUrl': previewUrl,
    };
  }
}
