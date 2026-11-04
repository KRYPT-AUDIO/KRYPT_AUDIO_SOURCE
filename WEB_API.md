# KRYPT AUDIO web port

The browser build uses the existing Flutter application and the same KRYPT UI, routes, library, playlists, lyrics, discovery, and playback model. Browser playback resolves YouTube-backed tracks through the separate PHP audio bridge in `php-api/`; Android continues to resolve streams using its existing Dart path.

## Build the web client

```bash
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /KRYPT_AUDIO/ \
  --dart-define=KRYPT_AUDIO_API_BASE=https://synapselabs.uk/api/krypt-audio
```

The repository workflow builds this automatically for the `web` branch. GitHub Pages is suitable for the static Flutter client; the PHP API must be uploaded to PHP hosting separately because GitHub Pages cannot execute PHP.

## PHP API upload

Upload `php-api/index.php`, `php-api/.htaccess`, and `php-api/README.md` to `https://synapselabs.uk/api/krypt-audio/`. Install PHP 8.1+, cURL, and `yt-dlp` on the host. The API supports `health`, `resolve`, and range-capable `stream` actions. Configure the allowed browser origins with `KRYPT_ALLOWED_ORIGINS` when the Pages URL differs from the defaults.

No Android keystore, Firebase private configuration, or Spotify client secret belongs in the browser repository or PHP API. Browser OAuth providers must be configured with their web origins and redirect URIs separately.
