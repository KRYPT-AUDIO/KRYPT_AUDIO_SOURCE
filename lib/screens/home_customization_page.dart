import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/services/home_customization_service.dart';
import 'package:musify/theme/krypt_design.dart';
import 'package:musify/widgets/glass_surface.dart';

class HomeCustomizationPage extends StatelessWidget {
  const HomeCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KryptHomeCustomizationService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Home')),
      body: AmbientBackdrop(
        child: AnimatedBuilder(
          animation: service,
          builder: (context, _) => ListView(
            padding: KryptDesign.pagePadding,
            children: [
              GlassSurface(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(KryptDesign.radiusLarge),
                opacity: .78,
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.home_24_filled,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your frequency, your layout',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Choose the sections that appear in your KRYPT feed.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KryptDesign.sectionGap),
              const KryptSectionHeader(
                title: 'Home sections',
                icon: FluentIcons.layout_column_three_24_filled,
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
                'Your favourites',
                'Show songs you have liked.',
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
    return GlassSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: BorderRadius.circular(KryptDesign.radiusMedium),
      child: SwitchListTile.adaptive(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
        value: value,
        onChanged: (next) async {
          try {
            await service.setValue(key, next);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not save Home customization.'),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
