import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/playlist_dialogs.dart';
import 'package:musify/widgets/glass_surface.dart';
import 'package:musify/widgets/now_playing/synced_lyrics_view.dart';
import 'package:musify/widgets/queue_list_view.dart';
import 'package:musify/widgets/song_artwork.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        initialData: audioHandler.mediaItem.value,
        builder: (context, snapshot) {
          final metadata = snapshot.data;
          if (metadata == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildPlayer(context, metadata);
        },
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, MediaItem metadata) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;
    final artworkWidth = (size.width - 40).clamp(260.0, 520.0).toDouble();
    final isLive = metadata.extras?['isLive'] == true;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(context, metadata),
                SizedBox(height: compact ? 16 : 28),
                _buildArtwork(metadata, artworkWidth, compact),
                SizedBox(height: compact ? 18 : 25),
                _buildTrackInfo(context, metadata),
                SizedBox(height: compact ? 17 : 24),
                if (!isLive) _buildProgress(context, metadata),
                if (!isLive) const SizedBox(height: 13),
                _buildTransport(context, metadata),
                const SizedBox(height: 22),
                _buildActionRail(context, metadata),
                if (_showDetails) ...[
                  const SizedBox(height: 16),
                  _buildTechnicalDetails(context, metadata),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MediaItem metadata) {
    return Row(
      children: [
        _circleButton(
          icon: FluentIcons.chevron_down_24_regular,
          tooltip: 'Close player',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'NOW PLAYING',
              style: TextStyle(
                color: Color(0xFFD9D8DF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
          ),
        ),
        _circleButton(
          icon: FluentIcons.apps_list_24_regular,
          tooltip: 'Queue',
          onPressed: () => _showQueue(context),
        ),
      ],
    );
  }

  Widget _buildArtwork(MediaItem metadata, double width, bool compact) {
    final artworkSize = math.min(width, compact ? 300.0 : 480.0);
    return Center(
      child: Hero(
        tag: 'now_playing_artwork',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey(metadata.id),
            width: artworkSize,
            height: artworkSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SongArtworkWidget(
              metadata: metadata,
              size: artworkSize,
              borderRadius: 28,
              errorWidgetIconSize: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, MediaItem metadata) {
    final artist = metadata.artist?.trim();
    final album = metadata.album?.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metadata.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                [
                  if (artist != null && artist.isNotEmpty) artist,
                  if (album != null && album.isNotEmpty) album,
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFAAA8B2),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _FavouriteButton(metadata: metadata),
      ],
    );
  }

  Widget _buildProgress(BuildContext context, MediaItem metadata) {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      initialData: audioHandler.currentPositionData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? audioHandler.currentPositionData;
        final duration = data.duration > Duration.zero
            ? data.duration
            : (metadata.duration ?? Duration.zero);
        final max = duration.inMilliseconds
            .toDouble()
            .clamp(1, double.infinity)
            .toDouble();
        final position = data.position.inMilliseconds
            .toDouble()
            .clamp(0, max)
            .toDouble();
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color(0xFF424149),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: .12),
              ),
              child: Slider(
                value: position,
                max: max,
                onChanged: (value) =>
                    audioHandler.seek(Duration(milliseconds: value.round())),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(data.position), style: _timeStyle),
                Text(_formatDuration(duration), style: _timeStyle),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransport(BuildContext context, MediaItem metadata) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      initialData: audioHandler.playbackState.value,
      builder: (context, snapshot) {
        final state = snapshot.data ?? audioHandler.playbackState.value;
        final loading =
            state.processingState == AudioProcessingState.loading ||
            state.processingState == AudioProcessingState.buffering;
        final playing = state.playing;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _modeButton(
              icon: FluentIcons.arrow_shuffle_24_regular,
              active: shuffleNotifier.value,
              onTap: () => audioHandler.setShuffleMode(
                shuffleNotifier.value
                    ? AudioServiceShuffleMode.none
                    : AudioServiceShuffleMode.all,
              ),
            ),
            _transportButton(
              FluentIcons.previous_24_filled,
              audioHandler.skipToPrevious,
            ),
            GestureDetector(
              onTap: loading
                  ? null
                  : (playing ? audioHandler.pause : audioHandler.play),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .14),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Icon(
                        playing
                            ? FluentIcons.pause_24_filled
                            : FluentIcons.play_24_filled,
                        color: Colors.black,
                        size: 32,
                      ),
              ),
            ),
            _transportButton(
              FluentIcons.next_24_filled,
              audioHandler.skipToNext,
            ),
            ValueListenableBuilder<AudioServiceRepeatMode>(
              valueListenable: repeatNotifier,
              builder: (_, mode, __) => _modeButton(
                icon: mode == AudioServiceRepeatMode.one
                    ? FluentIcons.arrow_repeat_1_24_regular
                    : FluentIcons.arrow_repeat_all_24_regular,
                active: mode != AudioServiceRepeatMode.none,
                onTap: () => audioHandler.setRepeatMode(
                  mode == AudioServiceRepeatMode.none
                      ? AudioServiceRepeatMode.all
                      : mode == AudioServiceRepeatMode.all
                      ? AudioServiceRepeatMode.one
                      : AudioServiceRepeatMode.none,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionRail(BuildContext context, MediaItem metadata) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: BorderRadius.circular(22),
      opacity: .72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _railButton(
            FluentIcons.text_quote_24_regular,
            'Lyrics',
            () => _showLyrics(context, metadata),
          ),
          _railButton(
            FluentIcons.album_add_24_regular,
            'Add',
            () => showAddToPlaylistDialog(
              context,
              song: mediaItemToMap(metadata),
            ),
          ),
          _railButton(
            FluentIcons.timer_24_regular,
            'Timer',
            () => _showTimer(context),
          ),
          _railButton(
            FluentIcons.sound_wave_circle_24_regular,
            'Equalizer',
            () => context.push('${NavigationManager.settingsPath}/equalizer'),
          ),
          _railButton(
            FluentIcons.info_24_regular,
            'Details',
            () => setState(() => _showDetails = !_showDetails),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails(BuildContext context, MediaItem metadata) {
    final extras = metadata.extras ?? const <String, dynamic>{};
    final source = _metadataValue(extras['source']);
    final codec = _metadataValue(extras['audioCodec'] ?? extras['codec']);
    final bitrate = _metadataValue(
      extras['audioBitrateKbps'] ?? extras['bitrateKbps'],
    );
    final sampleRate = _metadataValue(
      extras['sampleRate'] ?? extras['sampleRateHz'],
    );
    final rows = <Widget>[
      if (source != null) _detailLine('Source', source),
      if (codec != null) _detailLine('Format', codec),
      if (bitrate != null) _detailLine('Bitrate', '$bitrate kbps'),
      if (sampleRate != null) _detailLine('Sample rate', '$sampleRate Hz'),
    ];
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      opacity: .58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLAYBACK DETAILS',
            style: TextStyle(
              color: Color(0xFFAAA8B2),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No additional playback metadata is available for this track.',
              style: TextStyle(color: Color(0xFFAAA8B2)),
            )
          else
            ...rows,
        ],
      ),
    );
  }

  String? _metadataValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFAAA8B2))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLyrics(BuildContext context, MediaItem metadata) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LyricsSheet(metadata: metadata),
    );
  }

  Future<void> _showQueue(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .78,
        minChildSize: .45,
        maxChildSize: .94,
        expand: false,
        builder: (_, controller) => GlassSurface(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          opacity: .96,
          child: QueueWidget(isBottomSheet: true),
        ),
      ),
    );
  }

  Future<void> _showTimer(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSurface(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        opacity: .96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sleep timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (final minutes in [15, 30, 45, 60])
              ListTile(
                title: Text(
                  '$minutes minutes',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  audioHandler.setSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                },
              ),
            ListTile(
              title: const Text(
                'End of song',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                audioHandler.setSleepTimerEndOfSong();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF17171B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }

  Widget _transportButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 27),
      splashRadius: 28,
      tooltip: icon == FluentIcons.next_24_filled ? 'Next' : 'Previous',
    );
  }

  Widget _modeButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: active ? Colors.white : const Color(0xFF77757E),
        size: 22,
      ),
      splashRadius: 26,
    );
  }

  Widget _railButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFD1CFD8), size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAA8B2),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static const _timeStyle = TextStyle(color: Color(0xFFAAA8B2), fontSize: 12);
}

class _FavouriteButton extends StatefulWidget {
  const _FavouriteButton({required this.metadata});
  final MediaItem metadata;

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton> {
  late bool _liked;

  @override
  void initState() {
    super.initState();
    _liked = userLikedSongsList.value.any(
      (song) =>
          song is Map &&
          song['ytid']?.toString() ==
              widget.metadata.extras?['ytid']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final id = widget.metadata.extras?['ytid']?.toString();
        if (id == null) return;
        final next = !_liked;
        setState(() => _liked = next);
        try {
          await updateSongLikeStatus(
            id,
            next,
            songData: mediaItemToMap(widget.metadata),
          );
        } catch (_) {
          if (mounted) setState(() => _liked = !next);
        }
      },
      icon: Icon(
        _liked ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular,
        color: Colors.white,
        size: 28,
      ),
      tooltip: context.l10n!.likedSongs,
    );
  }
}

class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({required this.metadata});
  final MediaItem metadata;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  late Future<Lyrics?> _future;

  @override
  void initState() {
    super.initState();
    _future = getSongLyricsResult(
      widget.metadata.artist,
      widget.metadata.title,
      duration: widget.metadata.duration,
      album: widget.metadata.album,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .5,
      maxChildSize: .96,
      expand: false,
      builder: (_, controller) => GlassSurface(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        opacity: .98,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lyrics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    FluentIcons.dismiss_24_regular,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<Lyrics?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lyrics = snapshot.data;
                  if (lyrics == null || lyrics.isEmpty) {
                    return const Center(
                      child: Text(
                        'Lyrics are not available for this track.',
                        style: TextStyle(color: Color(0xFFAAA8B2)),
                      ),
                    );
                  }
                  if (lyrics.isSynced) return SyncedLyricsView(lyrics: lyrics);
                  return SingleChildScrollView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 36),
                    child: Text(
                      formatPlainLyrics(lyrics),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
