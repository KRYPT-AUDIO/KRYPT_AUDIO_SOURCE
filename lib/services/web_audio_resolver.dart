import 'package:flutter/foundation.dart';

/// Browser builds are safe to preview without credentials, hosting or a stream API.
/// Set KRYPT_WEB_DEMO_MODE=false and provide KRYPT_WEB_AUDIO_API_BASE_URL to
/// route catalog tracks through a future server-side audio resolver.
const bool kryptWebDemoMode = bool.fromEnvironment(
  'KRYPT_WEB_DEMO_MODE',
  defaultValue: true,
);

const String _webAudioApiBaseUrl = String.fromEnvironment(
  'KRYPT_WEB_AUDIO_API_BASE_URL',
);

class WebAudioResolver {
  const WebAudioResolver._();

  static String? resolve(Map song) {
    if (!kIsWeb) return null;

    if (kryptWebDemoMode || song['source'] == 'krypt-web-demo') {
      final assetName = song['demoAsset']?.toString();
      if (assetName == null || assetName.isEmpty) return null;
      // Flutter publishes bundled assets under this URL relative to the app's
      // configured <base href>, so GitHub Pages subpaths work as well as root hosts.
      return 'assets/assets/audio/$assetName';
    }

    final previewUrl = song['previewUrl']?.toString();
    if (previewUrl != null && previewUrl.isNotEmpty) return previewUrl;

    final baseUrl = _webAudioApiBaseUrl.trim();
    if (baseUrl.isEmpty) return null;

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalizedBaseUrl/stream.php').replace(
      queryParameters: {
        'id': song['ytid']?.toString() ?? '',
        if (song['isLive'] == true) 'live': '1',
      },
    );
    return uri.toString();
  }
}
