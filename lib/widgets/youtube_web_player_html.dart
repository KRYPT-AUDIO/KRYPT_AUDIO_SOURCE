import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

int _playerSequence = 0;

class OfficialYoutubePlayer extends StatefulWidget {
  const OfficialYoutubePlayer({super.key, required this.videoId});
  final String videoId;

  @override
  State<OfficialYoutubePlayer> createState() => _OfficialYoutubePlayerState();
}

class _OfficialYoutubePlayerState extends State<OfficialYoutubePlayer> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _register(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant OfficialYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) _register(widget.videoId);
  }

  void _register(String videoId) {
    _viewType = 'krypt-youtube-player-${_playerSequence++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final frame = html.IFrameElement()
        ..src = 'https://www.youtube.com/embed/${Uri.encodeComponent(videoId)}?autoplay=1&playsinline=1&rel=0&enablejsapi=1'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; encrypted-media; picture-in-picture'
        ..allowFullscreen = true;
      return frame;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
