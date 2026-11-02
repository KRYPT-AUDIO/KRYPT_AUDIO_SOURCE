import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class MusicSource {
  const MusicSource({
    required this.id,
    required this.name,
    required this.description,
  });
  final String id;
  final String name;
  final String description;
}

const availableMusicSources = <MusicSource>[
  MusicSource(
    id: 'youtube',
    name: 'YouTube Music',
    description: 'The full KRYPT catalogue and existing playback path.',
  ),
  MusicSource(
    id: 'audius',
    name: 'Audius',
    description: 'Independent music with a public streaming API.',
  ),
  MusicSource(
    id: 'jamendo',
    name: 'Jamendo',
    description:
        'Independent and Creative Commons catalogue; requires a client ID.',
  ),
];

class MusicSourceService {
  MusicSourceService._();
  static final instance = MusicSourceService._();
  late final ValueNotifier<List<String>> enabledNotifier =
      ValueNotifier<List<String>>(enabledIds);

  Box get _box => Hive.box('settings');

  List<String> get enabledIds {
    final configured = _box.get('enabledMusicSources');
    if (configured is List && configured.whereType<String>().isNotEmpty) {
      return configured.whereType<String>().toSet().toList();
    }
    return const ['youtube'];
  }

  bool isEnabled(String id) => enabledIds.contains(id);

  Future<void> setEnabled(String id, bool enabled) async {
    final values = enabledIds.toSet();
    if (enabled) {
      values.add(id);
    } else {
      values.remove(id);
    }
    if (values.isEmpty) values.add('youtube');
    await _box.put('enabledMusicSources', values.toList());
    enabledNotifier.value = values.toList(growable: false);
  }

  String get jamendoClientId =>
      (_box.get('jamendoClientId') as String? ?? '').trim();

  Future<void> setJamendoClientId(String value) =>
      _box.put('jamendoClientId', value.trim());

  Future<List<Map<String, dynamic>>> search(String query) async {
    final results = <Map<String, dynamic>>[];
    if (isEnabled('audius')) results.addAll(await _searchAudius(query));
    if (isEnabled('jamendo') && jamendoClientId.isNotEmpty) {
      results.addAll(await _searchJamendo(query));
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _searchAudius(String query) async {
    try {
      final uri = Uri.https('api.audius.co', '/v1/tracks/search', {
        'query': query,
        'app_name': 'KRYPT_AUDIO',
        'limit': '20',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body);
      final data = body is Map ? body['data'] : null;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) {
            final id = item['id']?.toString() ?? '';
            final artwork = item['artwork'] is Map
                ? item['artwork']['150x150']
                : null;
            return <String, dynamic>{
              'ytid': 'audius:$id',
              'source': 'audius',
              'sourceSongId': id,
              'title': item['title']?.toString() ?? 'Audius track',
              'artist': item['user'] is Map
                  ? item['user']['name']?.toString() ?? 'Audius'
                  : 'Audius',
              'album': 'Audius',
              'duration': item['duration'],
              'highResImage': artwork?.toString() ?? '',
              'lowResImage': artwork?.toString() ?? '',
              'streamUrl':
                  'https://api.audius.co/v1/tracks/$id/stream?app_name=KRYPT_AUDIO',
            };
          })
          .where((song) => (song['sourceSongId'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchJamendo(String query) async {
    try {
      final uri = Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': jamendoClientId,
        'format': 'json',
        'namesearch': query,
        'limit': '20',
        'audioformat': 'mp32',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body);
      final data = body is Map ? body['results'] : null;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) {
            final id = item['id']?.toString() ?? '';
            return <String, dynamic>{
              'ytid': 'jamendo:$id',
              'source': 'jamendo',
              'sourceSongId': id,
              'title': item['name']?.toString() ?? 'Jamendo track',
              'artist': item['artist_name']?.toString() ?? 'Jamendo',
              'album': item['album_name']?.toString() ?? 'Jamendo',
              'duration': item['duration'],
              'highResImage': item['album_image']?.toString() ?? '',
              'lowResImage': item['album_image']?.toString() ?? '',
              'streamUrl': item['audio']?.toString() ?? '',
            };
          })
          .where((song) => (song['streamUrl'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
