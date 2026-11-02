import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/services/smart_dj_service.dart';
import 'package:musify/theme/krypt_design.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/song_artwork.dart';

class SmartDjPage extends StatefulWidget {
  const SmartDjPage({super.key});

  @override
  State<SmartDjPage> createState() => _SmartDjPageState();
}

class _SmartDjPageState extends State<SmartDjPage> {
  final dj = SmartDjService.instance;
  bool _starting = false;

  Future<void> _startDj() async {
    setState(() => _starting = true);
    final started = await dj.start();
    if (mounted) {
      setState(() => _starting = false);
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart DJ needs a few songs in your library first.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dj,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('SMART DJ'),
            actions: [
              IconButton(
                tooltip: dj.isActive ? 'Stop Smart DJ' : 'Start Smart DJ',
                onPressed: dj.isActive ? dj.stop : _startDj,
                icon: Icon(
                  dj.isActive
                      ? FluentIcons.stop_24_filled
                      : FluentIcons.play_24_filled,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: KryptDesign.pagePadding,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(22),
                radius: KryptDesign.radiusLarge,
                opacity: 0.88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary],
                            ),
                          ),
                          child: const Icon(FluentIcons.speaker_2_24_filled),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KRYPT SMART DJ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'A fresh mix, curated on your device.',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mood',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SmartDjMood.values
                          .map(
                            (mood) => ChoiceChip(
                              label: Text(mood.label),
                              selected: dj.mood == mood,
                              onSelected: (_) => dj.setMood(mood),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          FluentIcons.music_note_2_24_regular,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Energy'),
                        const Spacer(),
                        Text(
                          dj.energy < 0.34
                              ? 'Low'
                              : dj.energy > 0.66
                              ? 'High'
                              : 'Balanced',
                        ),
                      ],
                    ),
                    Slider(value: dj.energy, onChanged: dj.setEnergy),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Spoken DJ introductions'),
                      subtitle: const Text(
                        'Uses your device’s local text-to-speech engine',
                      ),
                      value: dj.spoken,
                      onChanged: dj.setSpoken,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _starting ? null : _startDj,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(FluentIcons.sparkle_24_filled),
                      label: Text(
                        dj.isActive ? 'Regenerate mix' : 'Start Smart DJ',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Up next',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (dj.currentMix.isEmpty)
                GlassCard(
                  child: const Text(
                    'Your mix will appear here after you start Smart DJ.',
                  ),
                )
              else
                ...dj.currentMix.asMap().entries.map(
                  (entry) =>
                      _DjTrackTile(index: entry.key + 1, song: entry.value),
                ),
              const MiniPlayerBottomSpace(),
            ],
          ),
        );
      },
    );
  }
}

class _DjTrackTile extends StatelessWidget {
  const _DjTrackTile({required this.index, required this.song});
  final int index;
  final Map<String, dynamic> song;

  @override
  Widget build(BuildContext context) {
    final title = (song['title'] ?? 'Unknown track').toString();
    final artist = (song['artist'] ?? '').toString();
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      radius: 18,
      opacity: 0.62,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          SongArtworkWidget(
            metadata: mapToMediaItem(song),
            size: 46,
            borderRadius: 12,
            errorWidgetIconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
