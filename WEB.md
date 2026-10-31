# KRYPT AUDIO Web

The `web` branch packages the existing KRYPT AUDIO Flutter application for browsers and installable progressive web app use. It preserves the shared Dart application, theme, playback screens, search, library, playlists, lyrics, radio, settings, donation flow and Synapse Labs branding rather than maintaining a separate reduced web client.

## Local production build

```bash
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /KRYPT_AUDIO/
```

The output is written to `build/web`.

## GitHub Pages

`.github/workflows/deploy-web.yml` builds and deploys this branch automatically through GitHub Actions whenever `web` is pushed. In the repository settings, enable **Pages → Source: GitHub Actions** if it is not already enabled. The expected project URL is:

```text
https://drizzy-palace.github.io/KRYPT_AUDIO/
```

The workflow adds a `404.html` SPA fallback and `.nojekyll` so Flutter routes work when users refresh a deep link.

## Browser behavior

The web build uses browser-compatible implementations where available. Browser security rules still apply: downloads are saved through the browser, background media behavior depends on the browser, and some native-only capabilities such as Android media notifications, Android equaliser integration and desktop media-key bridges are not available in a normal browser tab.
