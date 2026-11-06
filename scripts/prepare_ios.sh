#!/usr/bin/env bash
set -euo pipefail

# Flutter keeps the iOS host project generated from the Flutter SDK. This makes
# the port reproducible in CI and for contributors without committing transient
# Pods or Xcode user data to the repository.
flutter create \
  --platforms=ios \
  --org com.synapselabs \
  --project-name krypt_audio \
  .

# Keep the iOS app identity aligned with the Android app and the existing deep
# links used by KRYPT AUDIO. PlistBuddy is available on macOS runners.
PLIST="ios/Runner/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName KRYPT AUDIO" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleName KRYPT AUDIO" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string com.synapselabs.kryptaudio" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string kryptaudio" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string musify" "$PLIST" 2>/dev/null || true

# The generated Runner target uses the Flutter application identifier from the
# org/project arguments above. Keep the generated CocoaPods integration intact.
flutter pub get
