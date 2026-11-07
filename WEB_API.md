# KRYPT AUDIO Web

The `web` branch builds the same Flutter application and KRYPT interface used by the Android app. Its default build is a self-contained demo: search, recommendations, playlists, library, lyrics, settings and playback controls are present, with a bundled original 32-second sample loop. Search and playback do not require a hosted audio API, provider credentials or a PHP service in this mode. Android continues using its existing source and playback implementation.

## Build the demo

```bash
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /KRYPT_AUDIO_SOURCE/ \
  --dart-define=KRYPT_WEB_DEMO_MODE=true
```

The web workflows build the demo automatically when `web` is pushed. GitHub Pages serves the Flutter client at `https://KRYPT-AUDIO.github.io/KRYPT_AUDIO_SOURCE/`; Pages does not need PHP or a separately deployed resolver for the demo.

The sample catalog uses original demo titles and a KRYPT Studio label. The bundled audio is a short generated preview used to exercise the full player, queue and playback controls; it is not a recording of the named music in the Android app.

## Add a hosted audio API later

The browser playback boundary is `lib/services/web_audio_resolver.dart`. To route non-demo tracks through a future server-side stream endpoint, build with demo mode disabled and the API base URL configured:

```bash
flutter build web --release --base-href /KRYPT_AUDIO_SOURCE/ \
  --dart-define=KRYPT_WEB_DEMO_MODE=false \
  --dart-define=KRYPT_WEB_AUDIO_API_BASE_URL=https://your-host.example/krypt-audio/api
```

The adapter expects a `stream.php?id=<track-id>` endpoint and adds `live=1` for live tracks. It returns direct provider preview URLs when a track contains `previewUrl`. Keep provider credentials and resolver tokens on the server; never put secrets in Dart defines or the browser bundle. Disabling demo mode also enables the existing optional Spotify/Deezer/iTunes search paths when their public/configured access is available.

The existing optional PHP bridge and Cloud Run resolver are retained under `api/` and `cloud-run-resolver/` for future integration. GitHub Pages cannot execute PHP, so upload the API directory to HTTPS PHP hosting and configure its server-side `.env` before enabling the adapter. See [`api/README.md`](api/README.md) and [`CLOUD_RUN_AUDIO.md`](CLOUD_RUN_AUDIO.md) for server setup.

## Optional Spotify web integration

The demo does not compile a Spotify client ID. To enable its optional browser sign-in/search integration, configure `KRYPT_SPOTIFY_CLIENT_ID` at build time and register the deployed URL as a Spotify redirect URI. This is separate from the future audio resolver and never embeds a client secret.
