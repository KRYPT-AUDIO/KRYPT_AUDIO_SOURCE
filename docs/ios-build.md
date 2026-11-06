# KRYPT AUDIO iOS port

The Flutter application already contains the shared mobile UI, playback service, deep-link handling, sharing intent handling, account services, and iOS-safe platform branches. The iOS work in this branch adds the missing Flutter iOS host target and CI packaging path.

## Local preparation

Run this on macOS with Xcode and the Flutter SDK version declared in `pubspec.yaml`:

```bash
bash scripts/prepare_ios.sh
open ios/Runner.xcworkspace
```

The script generates the standard Flutter `ios/` host project, sets the KRYPT AUDIO display name, and registers the existing `kryptaudio://` and `musify://` URL schemes. CocoaPods dependencies are resolved by `flutter pub get`.

Apple service configuration remains environment-specific. A real device/App Store build still requires the owning Apple Developer Team, bundle identifier provisioning, and any provider-specific values such as the Google Sign-In iOS client configuration.

## GitHub Actions

`.github/workflows/ios-unsigned-ipa.yml` runs on a macOS GitHub-hosted runner. It generates the iOS host target, resolves packages, analyzes Dart, runs:

```bash
flutter build ios --release --no-codesign
```

and packages the resulting `Runner.app` into `build/ios/ipa/KRYPT-AUDIO-<sha>-unsigned.ipa` as a downloadable workflow artifact. No Apple signing certificate, provisioning profile, or GitHub secret is used.

An unsigned IPA cannot be installed on a normal iPhone until it is signed and provisioned. It is intended for downstream signing, inspection, or CI handoff.
