import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/widgets/glass_surface.dart';

abstract final class KryptDesign {
  static const radiusSmall = 14.0;
  static const radiusMedium = 22.0;
  static const radiusLarge = 30.0;
  static const pagePadding = EdgeInsets.fromLTRB(18, 12, 18, 28);
  static const sectionGap = 24.0;
  static const fastMotion = Duration(milliseconds: 180);
  static const standardMotion = Duration(milliseconds: 320);
  static const slowMotion = Duration(milliseconds: 520);

  static const darkBackdrop = Color(0xFF070810);
  static const lightBackdrop = Color(0xFFF5F6FB);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF38BDF8);
  static const pink = Color(0xFFE879F9);
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.radius = KryptDesign.radiusMedium,
    this.opacity = 0.72,
    this.blur = 18,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double opacity;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = GlassSurface(
      padding: padding,
      margin: margin,
      borderRadius: BorderRadius.circular(radius),
      opacity: opacity,
      blur: blur,
      child: child,
    );
    return onTap == null
        ? surface
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: surface,
          );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: padding,
    margin: margin,
    radius: KryptDesign.radiusMedium,
    onTap: onTap,
    child: child,
  );
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.20)
            : colors.onSurface.withValues(alpha: 0.06),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    required this.controller,
    required this.hintText,
    super.key,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.loading = false,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      radius: KryptDesign.radiusLarge,
      opacity: 0.86,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            FluentIcons.search_24_regular,
            color: colors.primary,
          ),
          suffixIcon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          filled: false,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class KryptSectionHeader extends StatelessWidget {
  const KryptSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.action,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _Glow(
            color: colors.primary.withValues(alpha: 0.20),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -160,
          left: -120,
          child: _Glow(
            color: colors.secondary.withValues(alpha: 0.13),
            size: 330,
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}
