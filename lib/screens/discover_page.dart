import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/theme/krypt_design.dart';
import 'package:musify/widgets/glass_surface.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/recommended_songs_section.dart';
import 'package:musify/widgets/section_header.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverData {
  const _DiscoverData({required this.playlists, required this.songs});

  final List<dynamic> playlists;
  final List<dynamic> songs;
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const _moods = ['For you', 'Chill', 'Focus', 'Workout', 'Night'];
  String _selectedMood = _moods.first;
  late Future<_DiscoverData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_DiscoverData> _loadData() async {
    final query = _selectedMood == 'For you' ? null : _selectedMood;
    final results = await Future.wait<List<dynamic>>([
      getPlaylists(
        playlistsNum: recommendedCubesNumber,
        query: query,
        type: 'playlist',
      ),
      getRecommendedSongs(),
    ]);
    return _DiscoverData(playlists: results[0], songs: results[1]);
  }

  void _selectMood(String mood) {
    if (_selectedMood == mood) return;
    setState(() {
      _selectedMood = mood;
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.go('/search'),
            icon: const Icon(FluentIcons.search_24_regular),
          ),
        ],
      ),
      body: AmbientBackdrop(
        child: FutureBuilder<_DiscoverData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _DiscoverError(
                onRetry: () => setState(() => _dataFuture = _loadData()),
              );
            }
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () async => setState(() => _dataFuture = _loadData()),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: KryptDesign.pagePadding,
                children: [
                  GlassSurface(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(
                      KryptDesign.radiusLarge,
                    ),
                    opacity: .82,
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary],
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(13),
                            child: Icon(FluentIcons.sparkle_24_filled),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find your next frequency',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Fresh playlists and recommendations shaped by your listening.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _moods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final mood = _moods[index];
                        return ChoiceChip(
                          label: Text(mood),
                          selected: mood == _selectedMood,
                          onSelected: (_) => _selectMood(mood),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: KryptDesign.sectionGap),
                  if (data.playlists.isNotEmpty) ...[
                    SectionHeader(
                      title: _selectedMood == 'For you'
                          ? 'Made for you'
                          : '$_selectedMood mixes',
                      icon: FluentIcons.collections_24_filled,
                    ),
                    SizedBox(
                      height: 196,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.playlists.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final playlist = data.playlists[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/home/playlist/${playlist['ytid']}',
                            ),
                            child: PlaylistCube(playlist, size: 164),
                          );
                        },
                      ),
                    ),
                  ],
                  if (data.songs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    RecommendedSongsSection(
                      title: 'Songs to start with',
                      songs: data.songs,
                      listKeyPrefix: 'discover-${_selectedMood.toLowerCase()}',
                    ),
                  ],
                  const SizedBox(height: 12),
                  const MiniPlayerBottomSpace(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverError extends StatelessWidget {
  const _DiscoverError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.cloud_error_24_regular, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Discover could not load right now.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}
