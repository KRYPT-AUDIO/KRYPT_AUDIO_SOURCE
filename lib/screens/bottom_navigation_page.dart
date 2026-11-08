import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart'
    show closeCurrentBottomSheet;
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({required this.child, super.key});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  late final _miniPlayerStream = audioHandler.mediaItem
      .map((item) => item != null)
      .distinct();

  static const _items = <_NavItem>[
    _NavItem(
      'Home',
      FluentIcons.home_24_regular,
      FluentIcons.home_24_filled,
      0,
    ),
    _NavItem(
      'Search',
      FluentIcons.search_24_regular,
      FluentIcons.search_24_filled,
      2,
    ),
    _NavItem(
      'Discover',
      FluentIcons.sparkle_24_regular,
      FluentIcons.sparkle_24_filled,
      1,
    ),
    _NavItem(
      'Library',
      FluentIcons.library_24_regular,
      FluentIcons.library_24_filled,
      3,
    ),
    _NavItem(
      'Settings',
      FluentIcons.settings_24_regular,
      FluentIcons.settings_24_filled,
      4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: widget.child.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.child.currentIndex != 0) {
          widget.child.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: StreamBuilder<bool>(
          initialData: audioHandler.mediaItem.value != null,
          stream: _miniPlayerStream,
          builder: (context, snapshot) {
            final hasMiniPlayer = snapshot.data ?? false;
            return Stack(
              children: [
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: MediaQuery.of(context).padding.copyWith(
                      bottom:
                          MediaQuery.of(context).padding.bottom +
                          (hasMiniPlayer ? miniPlayerTotalHeight : 0),
                    ),
                  ),
                  child: widget.child,
                ),
                if (hasMiniPlayer)
                  const Positioned(
                    left: 8,
                    right: 8,
                    // Scaffold's body ends above bottomNavigationBar, so this
                    // is the direct gap between the mini-player and nav pill.
                    bottom: 16,
                    child: MiniPlayer(),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomPill(context),
      ),
    );
  }

  Widget _buildBottomPill(BuildContext context) {
    final selected = _items.indexWhere(
      (item) => item.shellIndex == widget.child.currentIndex,
    );
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44),
          color: Theme.of(context).colorScheme.surfaceContainerHigh
              .withValues(alpha: .96),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: _buildNavItem(context, _items[index], index == selected),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, bool selected) {
    return InkWell(
      onTap: () {
        closeCurrentBottomSheet();
        widget.child.goBranch(item.shellIndex, initialLocation: selected);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(38),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(36),
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .24),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon, this.shellIndex);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int shellIndex;
}
