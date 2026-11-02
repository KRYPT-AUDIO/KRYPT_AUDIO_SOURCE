import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/services/home_customization_service.dart';

class HomeCustomizationPage extends StatelessWidget {
  const HomeCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KryptHomeCustomizationService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Home')),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            const ListTile(
              leading: Icon(FluentIcons.home_24_filled),
              title: Text('Home screen layout'),
              subtitle: Text(
                'Choose the sections that appear in your KRYPT feed.',
              ),
            ),
            _toggle(
              context,
              service,
              'showSmartDj',
              'Smart DJ',
              'Show the in-player mix shortcut.',
              FluentIcons.sparkle_24_filled,
            ),
            _toggle(
              context,
              service,
              'showSuggested',
              'Suggested playlists',
              'Show discovery playlists.',
              FluentIcons.list_24_filled,
            ),
            _toggle(
              context,
              service,
              'showLiked',
              'Your favorites',
              'Show playlists you have liked.',
              FluentIcons.heart_24_filled,
            ),
            _toggle(
              context,
              service,
              'showRecap',
              'Listening recap',
              'Show your current listening recap.',
              FluentIcons.data_trending_24_filled,
            ),
            _toggle(
              context,
              service,
              'showRecommendations',
              'Recommended songs',
              'Show personalized song recommendations.',
              FluentIcons.music_note_2_24_filled,
            ),
            _toggle(
              context,
              service,
              'showPluginBadges',
              'Plugin badges',
              'Show active plugin status on Home.',
              FluentIcons.puzzle_cube_24_regular,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    KryptHomeCustomizationService service,
    String key,
    String title,
    String description,
    IconData icon,
  ) {
    final value = switch (key) {
      'showSmartDj' => service.showSmartDj,
      'showSuggested' => service.showSuggested,
      'showLiked' => service.showLiked,
      'showRecap' => service.showRecap,
      'showRecommendations' => service.showRecommendations,
      _ => service.showPluginBadges,
    };
    return Card(
      child: SwitchListTile.adaptive(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        value: value,
        onChanged: (next) => service.setValue(key, next),
      ),
    );
  }
}
