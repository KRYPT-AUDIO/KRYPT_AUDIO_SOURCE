import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/theme/krypt_design.dart';
import 'package:musify/widgets/glass_surface.dart';

class KryptVisualizer extends StatefulWidget {
  const KryptVisualizer({super.key});

  @override
  State<KryptVisualizer> createState() => _KryptVisualizerState();
}

class _KryptVisualizerState extends State<KryptVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation(PlaybackState? state) {
    final playing = state?.playing == true;
    if (playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        _syncAnimation(snapshot.data);
        return GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(KryptDesign.radiusMedium),
          opacity: .70,
          child: SizedBox(
            height: 42,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _VisualizerPainter(
                  progress: _controller.value,
                  primary: colors.primary,
                  secondary: colors.secondary,
                  active: snapshot.data?.playing == true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  const _VisualizerPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.active,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 32;
    final barWidth = size.width / (count * 1.7);
    final gap = barWidth * .7;
    final center = size.height / 2;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var index = 0; index < count; index++) {
      final phase = progress * math.pi * 2 + index * .43;
      final envelope = math.sin((index + 1) / count * math.pi);
      final pulse = active ? (math.sin(phase).abs() * .75 + .25) : .18;
      final height = size.height * .10 + size.height * .74 * envelope * pulse;
      paint.shader = LinearGradient(
        colors: [primary, secondary],
      ).createShader(Rect.fromLTWH(0, center - height, size.width, height * 2));
      final x = index * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, center - height / 2, barWidth, height),
          Radius.circular(barWidth),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.active != active;
}
