import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/listening_stats_service.dart';

class SmartDjService extends ChangeNotifier {
  SmartDjService._() {
    _spoken = settingsBox.get('smartDjSpoken', defaultValue: true) as bool;
    _energy = settingsBox.get('smartDjEnergy', defaultValue: 0.55) as double;
    _mood = settingsBox
        .get('smartDjMood', defaultValue: SmartDjMood.flow.name)
        .toString();
  }

  static final instance = SmartDjService._();
  static final _random = Random();
  static final settingsBox = Hive.box('settings');

  final FlutterTts _tts = FlutterTts();
  StreamSubscription<dynamic>? _mediaSubscription;
  List<Map<String, dynamic>> _currentMix = [];
  bool _isActive = false;
  bool _spoken = true;
  double _energy = 0.55;
  String _mood = SmartDjMood.flow.name;
  String? _lastAnnouncedId;

  bool get isActive => _isActive;
  bool get spoken => _spoken;
  double get energy => _energy;
  SmartDjMood get mood => SmartDjMood.values.firstWhere(
    (value) => value.name == _mood,
    orElse: () => SmartDjMood.flow,
  );
  List<Map<String, dynamic>> get currentMix => List.unmodifiable(_currentMix);

  void setSpoken(bool value) {
    _spoken = value;
    settingsBox.put('smartDjSpoken', value);
    notifyListeners();
    if (!value) unawaited(_tts.stop());
  }

  void setEnergy(double value) {
    _energy = value.clamp(0.0, 1.0);
    settingsBox.put('smartDjEnergy', _energy);
    notifyListeners();
  }

  void setMood(SmartDjMood value) {
    _mood = value.name;
    settingsBox.put('smartDjMood', value.name);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> buildMix({int length = 14}) async {
    final candidates = <Map<String, dynamic>>[];
    candidates.addAll(userLikedSongsList.value.whereType<Map>().map(_copySong));
    candidates.addAll(userOfflineSongs.value.whereType<Map>().map(_copySong));
    candidates.addAll(
      listeningStatsService
          .monthTopSongs(
            listeningStatsService.availableMonthKeys.isEmpty
                ? ''
                : listeningStatsService.availableMonthKeys.first,
          )
          .map(_copySong),
    );

    try {
      final recommendations = await getRecommendedSongs();
      candidates.addAll(recommendations.whereType<Map>().map(_copySong));
    } catch (error, stackTrace) {
      logger.log(
        'Smart DJ recommendations unavailable',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final unique = <String, Map<String, dynamic>>{};
    for (final song in candidates) {
      final id = _songId(song);
      if (id.isEmpty) continue;
      unique.putIfAbsent(id, () => song);
    }

    final ranked = unique.values.map((song) {
      final id = _songId(song);
      var score = 0.0;
      if (_containsSong(userLikedSongsList.value, id)) score += 4.0;
      if (_containsSong(userOfflineSongs.value, id)) score += 2.0;
      score += _moodScore(song) * 2.0;
      score += _energyScore(song);
      score += _random.nextDouble() * 1.8;
      return _RankedSong(song, score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    final mix = <Map<String, dynamic>>[];
    final artistCounts = <String, int>{};
    for (final rankedSong in ranked) {
      final artist = (rankedSong.song['artist'] ?? '').toString().toLowerCase();
      if (artist.isNotEmpty && (artistCounts[artist] ?? 0) >= 3) continue;
      mix.add(rankedSong.song);
      if (artist.isNotEmpty)
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      if (mix.length >= length) break;
    }

    _currentMix = mix;
    notifyListeners();
    return mix;
  }

  Future<bool> start({int length = 14}) async {
    final mix = await buildMix(length: length);
    if (mix.isEmpty) return false;

    _isActive = true;
    _lastAnnouncedId = null;
    await _mediaSubscription?.cancel();
    _mediaSubscription = audioHandler.mediaItem.listen((item) {
      if (!_isActive || item == null || !_spoken) return;
      if (_lastAnnouncedId == item.id) return;
      _lastAnnouncedId = item.id;
      unawaited(_announceTrack(item.title, item.artist));
    });

    await audioHandler.playPlaylistSong(
      playlist: {'title': 'KRYPT Smart DJ', 'list': mix},
      songIndex: 0,
      shuffle: false,
    );
    if (_spoken) {
      await _speak(
        'You are listening to KRYPT Smart DJ. I built a fresh mix for your ${mood.label.toLowerCase()} session.',
      );
    }
    notifyListeners();
    return true;
  }

  Future<void> stop() async {
    _isActive = false;
    await _mediaSubscription?.cancel();
    _mediaSubscription = null;
    await _tts.stop();
    notifyListeners();
  }

  Future<void> _announceTrack(String title, String? artist) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!_isActive || !_spoken) return;
    final name = artist == null || artist.isEmpty ? title : '$title by $artist';
    await _speak('Now playing $name.');
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-GB');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (error, stackTrace) {
      logger.log(
        'Smart DJ speech unavailable',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  double _moodScore(Map<String, dynamic> song) {
    final text =
        '${song['title'] ?? ''} ${song['album'] ?? ''} ${song['genre'] ?? ''}'
            .toLowerCase();
    final keywords = switch (mood) {
      SmartDjMood.chill => const [
        'chill',
        'acoustic',
        'slow',
        'ambient',
        'lofi',
        'sleep',
      ],
      SmartDjMood.focus => const [
        'instrumental',
        'focus',
        'study',
        'piano',
        'classical',
        'ambient',
      ],
      SmartDjMood.hype => const [
        'remix',
        'club',
        'dance',
        'workout',
        'party',
        'live',
      ],
      SmartDjMood.flow => const [
        'mix',
        'radio',
        'session',
        'night',
        'vibe',
        'wave',
      ],
    };
    return keywords.any(text.contains) ? 1.0 : 0.15;
  }

  double _energyScore(Map<String, dynamic> song) {
    final text = '${song['title'] ?? ''} ${song['album'] ?? ''}'.toLowerCase();
    final energetic = [
      'remix',
      'live',
      'club',
      'dance',
      'workout',
      'edit',
    ].any(text.contains);
    final target = _energy * 2.0;
    return energetic ? target : 2.0 - target;
  }

  static Map<String, dynamic> _copySong(Map song) =>
      Map<String, dynamic>.from(song);
  static String _songId(Map song) =>
      (song['ytid'] ?? song['id'] ?? song['url'] ?? '').toString();
  static bool _containsSong(List songs, String id) =>
      songs.any((song) => song is Map && _songId(song) == id);

  @override
  void dispose() {
    unawaited(_mediaSubscription?.cancel());
    unawaited(_tts.stop());
    super.dispose();
  }
}

enum SmartDjMood {
  flow('Flow'),
  chill('Chill'),
  focus('Focus'),
  hype('Hype');

  const SmartDjMood(this.label);
  final String label;
}

class _RankedSong {
  const _RankedSong(this.song, this.score);
  final Map<String, dynamic> song;
  final double score;
}
