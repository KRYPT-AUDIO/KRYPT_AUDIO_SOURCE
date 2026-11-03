<div align="center">
  <img src="https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/raw/main/.github/assets/KRYPT-Audio-banner.png" width="100%" alt="KRYPT AUDIO banner">

  # KRYPT AUDIO

  **A premium, open-source music experience by Synapse Labs UK Ltd.**

  [![GitHub release](https://img.shields.io/github/v/release/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE?style=flat-square&color=8B5CF6)](https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/releases)
  [![Android](https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/releases/latest)
  [![License](https://img.shields.io/github/license/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE?style=flat-square&color=38BDF8)](LICENSE)
  [![Stars](https://img.shields.io/github/stars/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE?style=flat-square&color=E879F9)](https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/stargazers)

  **Current release: V2.0.0 · Android build 20**
</div>

---

## About KRYPT AUDIO

KRYPT AUDIO is an independent Android music application developed and branded by **Synapse Labs UK Ltd**. It combines a dark Liquid Glass interface with search, playback, playlists, offline listening, lyrics, radio, integrations and local personalisation tools.

The project is based on the open-source [Musify](https://github.com/gokadzev/Musify) codebase and retains the upstream GPL-3.0 licensing and attribution requirements. KRYPT AUDIO is maintained as a separate branded project in this repository.

KRYPT AUDIO does not host or distribute copyrighted audio. Music is resolved from configured external sources, and users are responsible for complying with the laws and terms that apply to their use of those sources.

## V2.0.0 release status

V2.0.0 is the current Android release-hardening milestone. It includes the V1 feature set plus stability, recovery, branding and release-validation improvements:

- Consistent KRYPT Liquid Glass styling across the new profile and Home customisation surfaces.
- Actionable playback recovery with an in-player **Retry** and **Dismiss** control when a stream is interrupted.
- Permanent KRYPT AUDIO Android release signing configuration.
- Google account sign-in state and profile access.
- Spotify account integration for importing playlists and saved-song metadata into the local library.
- Configurable music sources, including YouTube, Audius and Jamendo where available.
- Custom `.kryptplugin` packages with an in-app marketplace and author guide.
- Local Smart DJ queue curation with optional spoken introductions using on-device Android text-to-speech.
- Custom profile display name, bio, avatar and accent colour.
- Home screen section customisation.
- Custom playlist artwork uploads.
- Listening statistics, recaps and recently played history.
- Offline playlists and download management.
- Lyrics, radio stations, equaliser controls and playback transitions.
- Android background playback, notification controls, home-screen playback widget and Android Auto support where supported by the device.
- Built-in release update checking and APK installation flow.

## Main features

### Playback and library

- Online search with suggestions.
- Queue management, repeat, shuffle and playback history.
- Background playback and Android media controls.
- Offline listening and playlist downloads.
- Playlists, playlist folders, custom artwork and import/export support.
- Lyrics and radio station support.
- Equaliser presets and volume headroom protection.
- SponsorBlock-aware playback where supported by the source.

### Personalisation

- Dark KRYPT Liquid Glass interface with violet, blue and ambient accent treatments.
- Custom profile display name, bio, avatar and accent colour.
- Configurable Home screen sections.
- Listening statistics and recap views.
- Smooth playback fade transitions.
- Home-screen playback widget.

### Integrations and sources

- Google account sign-in for account state and identity.
- Spotify OAuth login and library import for playlists and saved-song metadata. Spotify import does not replace KRYPT AUDIO playback sources.
- YouTube, Audius and Jamendo source support where available and enabled in Settings.
- Android Auto media browsing and controls where supported.

### KRYPT plugin system

KRYPT AUDIO supports community `.kryptplugin` packages. The marketplace reads its catalogue from the `plugins/index.json` file in the `main` branch of this repository.

A plugin package is a ZIP archive using the custom `.kryptplugin` extension. Packages can contain:

```text
manifest.json
plugin.js
theme.css
```

Plugins can declare supported hooks and theme tokens. The current safe runtime applies declared theme tokens and handles declarative hooks; it does **not** execute downloaded JavaScript with unrestricted native access. Use **Settings → Plugin Marketplace → Plugin guide** for the current package format, permissions and authoring guidance.

## Download

Download the latest signed Android APK from the [GitHub Releases page](https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/releases/latest).

Direct V2.0.0 release assets may be added to the release page separately. The V2.0.0 APK built from this repository is signed with the KRYPT AUDIO release certificate and uses the Android package ID:

```text
com.synapselabs.kryptaudio
```

Always verify that an APK came from the official [KRYPT-AUDIO/KRYPT_AUDIO_SOURCE repository](https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE) before installing it.

## Supported platforms

| Platform | Status |
| --- | --- |
| Android | Supported and actively released |
| iOS | Not currently supported |
| Linux | Source contains inherited desktop support; no V2 Android release is provided for Linux |
| Windows | Source contains inherited desktop support; no V2 Android release is provided for Windows |

V2 development and release validation are Android-only for now.

## Building from source

### Requirements

- Flutter 3.47.7
- Dart 3.13.5
- Android SDK with API 36
- OpenJDK 17
- Android ARM64-capable test device or emulator

### Build commands

```bash
git clone https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE.git
cd KRYPT_AUDIO_SOURCE
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The repository's release build uses the Android `github` flavour. A locally configured signing key is required to reproduce the signed release APK. Never commit keystores, passwords, OAuth secrets or Firebase service credentials to the repository.

### Tests and network checks

The normal test suite is deterministic and does not require YouTube access. The current suite contains 89 passing tests, with external YouTube stream checks disabled by default because they depend on provider and proxy availability.

To intentionally run the live YouTube smoke tests:

```bash
KRYPT_LIVE_TESTS=true flutter test test/fetch_audio_stream_live_test.dart
```

A live test failure can indicate provider rate limiting, proxy failure or network conditions rather than an application code regression.

## Account and integration setup

Some optional integrations require their own developer configuration:

- Google Sign-In requires an Android OAuth client matching `com.synapselabs.kryptaudio` and the certificate SHA-1 for the APK being installed.
- Spotify import requires a Spotify Developer application with the redirect URI configured by the app and a valid client ID.
- Source availability depends on the external provider and may change independently of KRYPT AUDIO.

Do not publish API keys, client secrets, signing passwords or Firebase private credentials in issues, screenshots or pull requests.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

When contributing:

- Preserve the GPL-3.0 license and upstream Musify attribution.
- Keep Android playback and offline behaviour intact.
- Avoid committing credentials or private signing material.
- Run `flutter analyze` and `flutter test` before submitting changes.
- Keep user-facing screens aligned with the KRYPT Liquid Glass design system.

## Credits and upstream attribution

KRYPT AUDIO is built from and inspired by the open-source [Musify project](https://github.com/gokadzev/Musify) by Valeri Gokadze and its contributors. Please see the repository history and source headers for the applicable upstream attribution.

## License

Copyright © 2026 Synapse Labs UK Ltd.

KRYPT AUDIO is free software licensed under the **GNU General Public License v3.0**. You may use, modify and distribute the software under the terms of that license, provided that you retain the required copyright notices, license text, source availability and notices of changes.

See [LICENSE](LICENSE) for the complete license text.

## Disclaimer

KRYPT AUDIO and its contributors do not host, own or distribute copyrighted audio content. The application provides access to content through external services, configured sources and interoperability integrations. All trademarks, songs, audio files and related content remain the property of their respective owners.

Users are solely responsible for ensuring that their use of KRYPT AUDIO, external services and third-party plugins complies with applicable law and the terms of service of those providers. The developers do not encourage or endorse copyright infringement and assume no liability for misuse of the software or third-party integrations.
