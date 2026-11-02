import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/web_api.dart';

class OfficialYoutubeApi {
  static Uri _endpoint(String query, String type) {
    return Uri.parse('$kryptWebApiBaseUrl/search.php').replace(
      queryParameters: {
        'q': query,
        'type': type,
        'maxResults': '25',
      },
    );
  }

  static Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    return _search(query, 'video');
  }

  static Future<List<Map<String, dynamic>>> searchPlaylists(
    String query,
  ) async {
    return _search(query, 'playlist');
  }

  static Future<List<Map<String, dynamic>>> searchChannels(
    String query,
  ) async {
    return _search(query, 'channel');
  }

  static Future<List<Map<String, dynamic>>> _search(
    String query,
    String type,
  ) async {
    if (!kIsWeb || kryptWebApiBaseUrl.isEmpty || query.trim().isEmpty) {
      return [];
    }
    try {
      final response = await http
          .get(_endpoint(query.trim(), type), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final decoded = jsonDecode(response.body);
      final items = decoded is Map ? decoded['items'] : null;
      if (items is! List) return [];
      return items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic>? idOf(Map<String, dynamic> item) {
    final id = item['id'];
    final snippet = item['snippet'];
    if (id is! Map || snippet is! Map) return null;
    final kind = id['kind']?.toString() ?? '';
    final value = kind.endsWith('#video')
        ? id['videoId']
        : kind.endsWith('#playlist')
        ? id['playlistId']
        : id['channelId'];
    if (value == null || value.toString().isEmpty) return null;
    final thumbnails = snippet['thumbnails'];
    String? image;
    if (thumbnails is Map) {
      final preferred = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'];
      if (preferred is Map) image = preferred['url']?.toString();
    }
    return {
      'ytid': value.toString(),
      'title': snippet['title']?.toString() ?? '',
      'description': snippet['description']?.toString() ?? '',
      'image': image,
      'channelTitle': snippet['channelTitle']?.toString() ?? '',
      'publishedAt': snippet['publishedAt']?.toString(),
      'kind': kind,
      'source': 'youtube-official',
    };
  }
}
