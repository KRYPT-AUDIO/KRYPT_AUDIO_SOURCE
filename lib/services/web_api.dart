import 'package:flutter/foundation.dart';

/// Public KRYPT AUDIO API endpoint used only by browser builds.
const kryptWebApiBaseUrl =
    String.fromEnvironment(
      'KRYPT_WEB_API_BASE_URL',
      defaultValue: 'https://synapselabs.uk/krypt-audio/api',
    );

bool _isProxyableHost(String host) {
  final normalized = host.toLowerCase();
  return normalized.endsWith('googlevideo.com') ||
      normalized.endsWith('youtube.com') ||
      normalized.endsWith('ytimg.com') ||
      normalized.endsWith('ggpht.com') ||
      normalized.endsWith('googleusercontent.com');
}

/// Routes a YouTube/Google Video URL through the PHP bridge on Web.
Uri routeWebMediaUrl(Uri url) {
  if (!kIsWeb || kryptWebApiBaseUrl.isEmpty || !_isProxyableHost(url.host)) {
    return url;
  }
  return Uri.parse('$kryptWebApiBaseUrl/proxy.php').replace(
    queryParameters: {'url': url.toString()},
  );
}
