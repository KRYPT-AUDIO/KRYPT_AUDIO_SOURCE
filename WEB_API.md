# KRYPT AUDIO web port

The browser build uses the existing Flutter application and the same KRYPT UI, routes, library, playlists, lyrics, discovery, and playback model. Browser playback resolves YouTube-backed tracks through the PHP audio bridge in `api/stream.php`; Android continues to resolve streams using its existing Dart path.

## Build the web client

```bash
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /KRYPT_AUDIO_SOURCE/ \
  --dart-define=KRYPT_WEB_API_BASE_URL=https://synapselabs.uk/krypt-audio/api \
  --dart-define=KRYPT_SPOTIFY_CLIENT_ID=abb77bc3863f4f8fab60434b4a86e2f5
```

The repository workflow builds this automatically for the `web` branch. GitHub Pages is suitable for the static Flutter client; the PHP API must be uploaded to PHP hosting separately because GitHub Pages cannot execute PHP.

## PHP API upload

Upload the contents of `api/` to `https://synapselabs.uk/krypt-audio/api/`. Install PHP 8.0+, cURL, and `yt-dlp` on the host. The `stream.php` endpoint resolves and range-proxies the same YouTube audio stream family used by Android. The existing `health.php`, `search.php`, and allow-listed `proxy.php` endpoints remain available for the rest of the web client.

Configure `KRYPT_YTDLP_BIN` if `yt-dlp` is not on the PHP process PATH. Configure the allowed browser origin in `.env` using `ALLOWED_ORIGIN`. Never upload Firebase private files, Android keystores, Spotify client secrets, or a real `.env` file to GitHub.
