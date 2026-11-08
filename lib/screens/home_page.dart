import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/home_customization_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/plugin_service.dart';
import 'package:musify/theme/krypt_design.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/listening_stats_utils.dart';
import 'package:musify/widgets/glass_surface.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_artwork.dart';
import 'package:musify/widgets/song_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List> _playlistsFuture;
  late Future<List> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = getPlaylists(playlistsNum: 6);
    _recommendationsFuture = getRecommendedSongs();
  }

  @override
  Widget build(BuildContext context) {
    final customization = KryptHomeCustomizationService.instance;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedBuilder(
        animation: customization,
        builder: (context, _) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: KryptDesign.pagePadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildFrequencyCard(context),
                  if (customization.showSmartDj) ...[
                    const SizedBox(height: 14),
                    _buildSmartDjCard(context),
                  ],
                  if (customization.showPluginBadges) ...[
                    const SizedBox(height: 14),
                    _buildPluginStatus(context),
                  ],
                  const SizedBox(height: 30),
                  if (customization.showSuggested) ...[
                    _buildSectionTitle(
                      context,
                      icon: FluentIcons.text_bullet_list_24_regular,
                      title: 'Suggested playlists',
                      action: 'See all',
                      onAction: () => context.go('/library'),
                    ),
                    const SizedBox(height: 12),
                    _buildPlaylistShelf(),
                    const SizedBox(height: 30),
                  ],
                  if (customization.showLiked) ...[
                    _buildSectionTitle(
                      context,
                      icon: FluentIcons.heart_24_regular,
                      title: 'Your favourites',
                      action: 'See all',
                      onAction: () => context.go('/library'),
                    ),
                    const SizedBox(height: 12),
                    _buildLikedSongs(),
                    const SizedBox(height: 30),
                  ],
                  if (customization.showRecap) ...[
                    _buildSectionTitle(
                      context,
                      icon: FluentIcons.history_24_regular,
                      title: 'Time Machine',
                      onAction: () => context.push('/home/timeMachine'),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeMachine(context),
                    const SizedBox(height: 14),
                    _buildListeningStatsButton(context),
                    const SizedBox(height: 30),
                  ],
                  if (customization.showRecommendations) ...[
                    _buildSectionTitle(
                      context,
                      icon: FluentIcons.sparkle_24_regular,
                      title: 'Recommended for you',
                      trailingPlay: true,
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendations(),
                  ],
                  const MiniPlayerBottomSpace(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'KRYPT AUDIO',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2),
          ),
        ),
        _roundHeaderButton(
          context,
          FluentIcons.alert_24_regular,
          'Announcements',
          () => _showKryptMessage(context),
        ),
        const SizedBox(width: 12),
        _roundHeaderButton(
          context,
          FluentIcons.person_24_filled,
          'Profile',
          () => context.push('/settings/profile'),
        ),
      ],
    );
  }

  void _showKryptMessage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KRYPT SIGNAL'),
        content: const Text('The frequency is clear. Keep listening.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _roundHeaderButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyCard(BuildContext context) {
    return _glassCard(
      height: 100,
      onTap: () => context.push('/search'),
      child: Row(
        children: [
          _iconOrb(FluentIcons.pulse_24_regular),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR FREQUENCY, ELEVATED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'A space for every sound.',
                  style: TextStyle(color: Color(0xFFB8B7C2), fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(FluentIcons.chevron_right_24_regular, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSmartDjCard(BuildContext context) {
    return _glassCard(
      height: 100,
      onTap: () => context.push('/home/smartDj'),
      child: Row(
        children: [
          _iconOrb(FluentIcons.sparkle_24_filled),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KRYPT SMART DJ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'A fresh mix curated from your library.',
                  style: TextStyle(color: Color(0xFFB8B7C2), fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(FluentIcons.chevron_right_24_regular, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPluginStatus(BuildContext context) {
    final pluginService = KryptPluginService.instance;
    return AnimatedBuilder(
      animation: pluginService,
      builder: (context, _) {
        final enabledPlugins = pluginService.installed
            .where((plugin) => plugin.enabled)
            .toList(growable: false);
        return InkWell(
          onTap: () => context.push('/settings/plugins'),
          borderRadius: BorderRadius.circular(22),
          child: GlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: BorderRadius.circular(22),
            opacity: .68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FluentIcons.puzzle_cube_24_regular,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        enabledPlugins.isEmpty
                            ? 'No enabled plugins'
                            : 'Active plugins',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (enabledPlugins.isEmpty)
                      Icon(
                        FluentIcons.chevron_right_24_regular,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                if (enabledPlugins.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: enabledPlugins.take(3).map((plugin) {
                      return Chip(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            plugin.manifest.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                  if (enabledPlugins.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${enabledPlugins.length - 3} more',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikedSongs() {
    return ValueListenableBuilder<List>(
      valueListenable: userLikedSongsList,
      builder: (context, songs, _) {
        if (songs.isEmpty) {
          return GlassSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            opacity: .62,
            child: Text(
              'Like a song and it will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return GlassSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          borderRadius: BorderRadius.circular(22),
          opacity: .62,
          child: Column(
            children: songs.take(4).map<Widget>((song) {
              return SongBar(
                song,
                true,
                isFromLikedSongs: true,
                showQueueActions: false,
                borderRadius: BorderRadius.circular(16),
                barPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _iconOrb(IconData icon) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF25252D),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFC7FF).withValues(alpha: .22),
            blurRadius: 18,
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Icon(icon, color: const Color(0xFFDCE2FF), size: 28),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? action,
    VoidCallback? onAction,
    bool trailingPlay = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFCFD5FF), size: 27),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (trailingPlay)
          InkWell(
            onTap: () async {
              final songs = await _recommendationsFuture;
              if (songs.isNotEmpty) {
                await audioHandler.playPlaylistSong(
                  playlist: {'title': title, 'list': songs},
                  songIndex: 0,
                );
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                FluentIcons.play_circle_24_filled,
                color: Colors.white,
                size: 35,
              ),
            ),
          )
        else if (action != null)
          InkWell(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(width: 8),
                const Icon(
                  FluentIcons.chevron_right_24_regular,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaylistShelf() {
    return SizedBox(
      height: 226,
      child: AsyncLoader<List<dynamic>>(
        future: _playlistsFuture,
        builder: (context, playlists) {
          if (playlists.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: playlists.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final playlist = playlists[index] as Map;
              return _playlistTile(context, playlist);
            },
          );
        },
      ),
    );
  }

  Widget _playlistTile(BuildContext context, Map playlist) {
    final image = playlist['image']?.toString();
    return SizedBox(
      width: 186,
      child: InkWell(
        onTap: () => context.push('/home/playlist/${playlist['ytid']}'),
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            color: const Color(0xFF17171B),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null && image.isNotEmpty)
                  PlaylistArtwork(
                    playlistArtwork: image,
                    size: 186,
                    cubeIcon: FluentIcons.music_note_2_24_filled,
                  )
                else
                  const ColoredBox(color: Color(0xFF25252B)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _typePill(
                    playlist['isAlbum'] == true ? 'Album' : 'Playlist',
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                    ),
                    child: const Icon(
                      FluentIcons.play_24_filled,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typePill(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF727484).withValues(alpha: .85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTimeMachine(BuildContext context) {
    final currentMonthKey = listeningStatsMonthKey(DateTime.now());
    final monthStats = listeningStatsService.monthStats(currentMonthKey);
    final songs = listeningStatsService.monthTopSongs(currentMonthKey);
    final minutes = monthDisplayMinutes(monthStats);
    final preview = songs.take(1).toList();
    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(18, 17, 15, 16),
      borderRadius: BorderRadius.circular(25),
      opacity: .66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$minutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'minutes listened',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Spacer(),
              _datePill(
                formatMonthPeriodLabel(
                  Localizations.localeOf(context),
                  currentMonthKey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (preview.isNotEmpty)
            InkWell(
              onTap: () => audioHandler.playPlaylistSong(
                playlist: {'title': 'Time Machine', 'list': preview},
                songIndex: 0,
              ),
              child: Row(
                children: [
                  _smallArtwork(preview.first),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.first['title']?.toString() ??
                              'Your listening history',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview.first['artist']?.toString() ?? 'KRYPT AUDIO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB8B7C2),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    FluentIcons.more_vertical_24_regular,
                    color: Colors.white,
                  ),
                ],
              ),
            )
          else
            const Text(
              'Your listening history will appear here.',
              style: TextStyle(color: Color(0xFFB8B7C2)),
            ),
        ],
      ),
    );
  }

  Widget _datePill(String label) {
    return Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF6E6F7B).withValues(alpha: .50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _smallArtwork(Map song) {
    final image = song['image'] ?? song['lowResImage'] ?? song['highResImage'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: image == null
          ? const ColoredBox(
              color: Color(0xFF303039),
              child: SizedBox(width: 56, height: 56),
            )
          : Image.network(
              image.toString(),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF303039),
                child: SizedBox(width: 56, height: 56),
              ),
            ),
    );
  }

  Widget _buildListeningStatsButton(BuildContext context) {
    return _glassCard(
      height: 60,
      onTap: () => context.push('/home/timeMachine'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(FluentIcons.data_bar_vertical_24_regular, color: Colors.white),
          SizedBox(width: 12),
          Text(
            'Listening stats',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Spacer(),
          Icon(FluentIcons.chevron_right_24_regular, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return AsyncLoader<List<dynamic>>(
      future: _recommendationsFuture,
      builder: (context, songs) {
        if (songs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'Keep listening and KRYPT will build your mix.',
              style: TextStyle(color: Color(0xFFB8B7C2)),
            ),
          );
        }
        return GlassSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          borderRadius: BorderRadius.circular(22),
          opacity: .62,
          child: Column(
            children: songs.take(6).toList().asMap().entries.map((entry) {
              final song = entry.value;
              return SongBar(
                song,
                true,
                barPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                borderRadius: BorderRadius.circular(16),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _glassCard({
    required Widget child,
    double? height,
    VoidCallback? onTap,
  }) {
    final surface = GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      borderRadius: BorderRadius.circular(29),
      opacity: .68,
      child: child,
    );
    final card = height == null
        ? surface
        : SizedBox(height: height, child: surface);
    return onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(29),
            child: card,
          );
  }
}
