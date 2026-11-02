import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/spotify_service.dart';
import 'package:musify/utilities/flutter_toast.dart';

class SpotifyLibraryPage extends StatefulWidget {
  const SpotifyLibraryPage({super.key});

  @override
  State<SpotifyLibraryPage> createState() => _SpotifyLibraryPageState();
}

class _SpotifyLibraryPageState extends State<SpotifyLibraryPage> {
  final service = SpotifyService.instance;
  bool _syncing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    service.addListener(_onChanged);
  }

  @override
  void dispose() {
    service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    final opened = await service.beginLogin();
    if (!opened && mounted)
      showToast(context, service.error ?? 'Could not open Spotify sign-in');
  }

  Future<void> _sync() async {
    if (_syncing || !service.isConnected) return;
    setState(() {
      _syncing = true;
      _status = 'Loading Spotify playlists and Liked Songs…';
    });
    try {
      final playlists = await service.loadPlaylists();
      var importedPlaylists = 0;
      for (final playlist in playlists) {
        final name = (playlist['name'] as String?)?.trim();
        final id = playlist['id'] as String?;
        if (name == null || name.isEmpty || id == null) continue;
        final tracks = await service.loadPlaylistTracks(id);
        final (_, playlistId) = createCustomPlaylist(
          'Spotify · $name',
          _imageUrl(playlist),
          context,
        );
        final songs = tracks.map(_trackToSong).whereType<Map>().toList();
        addSongsInCustomPlaylist(context, playlistId, songs);
        importedPlaylists++;
      }
      final liked = await service.loadLikedSongs();
      if (liked.isNotEmpty) {
        final (_, playlistId) = createCustomPlaylist(
          'Spotify · Liked Songs',
          _imageUrl(liked.first['track']),
          context,
        );
        addSongsInCustomPlaylist(
          context,
          playlistId,
          liked.map(_trackToSong).whereType<Map>().toList(),
        );
      }
      if (mounted) {
        setState(
          () => _status =
              'Imported $importedPlaylists playlists and ${liked.length} Liked Songs.',
        );
        showToast(context, 'Spotify library synced');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Sync failed: $error');
        showToast(context, 'Spotify sync failed');
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Map<String, dynamic>? _trackToSong(Map<String, dynamic> item) {
    final nestedTrack = item['item'] ?? item['track'];
    final track = nestedTrack is Map
        ? Map<String, dynamic>.from(nestedTrack)
        : item;
    final id = track['id'] as String?;
    final title = track['name'] as String?;
    if (id == null || title == null || title.isEmpty) return null;
    final artists = (track['artists'] as List? ?? const [])
        .whereType<Map>()
        .map((artist) => artist['name']?.toString())
        .whereType<String>()
        .join(', ');
    return {
      'ytid': 'spotify:$id',
      'title': title,
      'artist': artists,
      'album': (track['album'] as Map?)?['name']?.toString() ?? '',
      'image': _imageUrl(track),
      'source': 'spotify-library',
      'spotifyId': id,
      'isPlayable': false,
    };
  }

  String? _imageUrl(dynamic item) {
    final images = item is Map ? item['images'] : null;
    if (images is List && images.isNotEmpty && images.first is Map) {
      return (images.first as Map)['url']?.toString();
    }
    final album = item is Map ? item['album'] : null;
    if (album is Map) return _imageUrl(album);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final connected = service.isConnected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify library'),
        leading: IconButton(
          icon: const Icon(FluentIcons.arrow_left_24_regular),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(FluentIcons.music_note_2_24_filled),
              ),
              title: Text(
                connected
                    ? (service.displayName ?? 'Spotify connected')
                    : 'Connect Spotify',
              ),
              subtitle: Text(
                connected
                    ? (service.email ?? 'Your Spotify account is connected.')
                    : 'Import playlists and Liked Songs into your KRYPT library.',
              ),
              trailing: connected
                  ? IconButton(
                      tooltip: 'Disconnect Spotify',
                      icon: const Icon(FluentIcons.sign_out_24_regular),
                      onPressed: service.disconnect,
                    )
                  : FilledButton(
                      onPressed: service.isBusy ? null : _connect,
                      child: const Text('Connect'),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (connected)
            FilledButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.arrow_sync_24_regular),
              label: Text(_syncing ? 'Syncing…' : 'Sync Spotify library'),
            ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          const Text(
            'KRYPT AUDIO imports Spotify library metadata only. Existing KRYPT playback sources remain unchanged; Spotify audio is not streamed by this app.',
          ),
        ],
      ),
    );
  }
}
