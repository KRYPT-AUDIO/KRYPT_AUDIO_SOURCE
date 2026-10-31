# KRYPT AUDIO V1.0.1

## Plugins Support Release

**Release date:** 31 October 2026  
**Application:** KRYPT AUDIO  
**Version:** `1.0.1+2`  
**Publisher:** Synapse Labs UK Ltd  
**Platform:** Android ARM64  
**Repository:** https://github.com/drizzy-palace/KRYPT_AUDIO

---

## Overview

KRYPT AUDIO V1.0.1 introduces the first version of the KRYPT plugin system. The release gives users a controlled way to install community-created themes and future app customisations without changing the core music playback application or requiring a separate fork of KRYPT AUDIO.

The plugin system is designed around a custom `.kryptplugin` package format. A package is a ZIP archive with a custom extension containing a validated manifest, JavaScript entry point, CSS stylesheet and optional assets. Marketplace metadata is hosted in a dedicated GitHub `plugins` branch, allowing the catalogue to be updated independently from the main application source.

This release focuses on a safe, theme-first foundation. CSS-based personalisation is active in V1.0.1. JavaScript files are packaged, validated and retained as plugin entry points, but unrestricted downloaded JavaScript is not executed inside the native Flutter process in this release.

---

## Highlights

### Built-in Plugin Marketplace

A new **Settings → Plugin Marketplace** screen provides a native marketplace experience inside KRYPT AUDIO.

The marketplace:

- Fetches plugin metadata from the GitHub-hosted marketplace index.
- Filters plugins according to the minimum supported KRYPT AUDIO version.
- Displays plugin name, version, description and author.
- Allows users to install compatible plugins directly from the app.
- Shows installed plugins separately from available marketplace plugins.
- Provides enable, disable and uninstall controls.
- Supports pull-to-refresh and manual marketplace refresh.
- Displays clear error feedback when the marketplace is unavailable.

The current marketplace index is hosted at:

```text
https://raw.githubusercontent.com/drizzy-palace/KRYPT_AUDIO/plugins/index.json
```

### Custom `.kryptplugin` Package Format

KRYPT plugin packages use the `.kryptplugin` extension. Internally, the package is a ZIP archive with a predictable structure:

```text
my-plugin.kryptplugin
├── manifest.json
├── plugin.js
├── theme.css
└── assets/
    └── optional-assets
```

The extension makes plugin files recognisable as KRYPT AUDIO packages while retaining a portable archive format that can be generated using standard ZIP tooling.

### Manifest Validation

Every package must include a valid `manifest.json`. The application validates:

- Plugin identifier format.
- Required display and author metadata.
- Plugin version.
- Minimum KRYPT AUDIO version.
- JavaScript entry-point path.
- CSS stylesheet path.
- HTTPS download URL metadata.
- Declared permissions.
- Package ID matching the marketplace entry.

A package is rejected if its manifest is missing, malformed, incompatible, or inconsistent with the marketplace metadata.

### Safe Installation Flow

Plugin installation uses a staged process:

1. Download the package from its marketplace URL.
2. Decode the ZIP archive.
3. Reject unsafe absolute paths and parent-directory traversal.
4. Extract to a temporary staging directory.
5. Validate the package manifest.
6. Confirm the declared JavaScript and CSS entry files exist.
7. Replace the previous plugin directory atomically.
8. Persist the installed-plugin record.
9. Apply enabled theme tokens.

This prevents incomplete downloads from being treated as installed plugins and protects the application data directory from archive path traversal.

### CSS Theme Runtime

Enabled plugin stylesheets may define supported KRYPT theme tokens using a CSS-like `:root` block:

```css
:root {
  --krypt-primary: #9b7cff;
  --krypt-secondary: #36c8ff;
  --krypt-background: #080611;
  --krypt-surface: #17132a;
  --krypt-radius: 24px;
}
```

V1.0.1 currently applies these tokens:

- `--krypt-primary`
- `--krypt-secondary`
- `--krypt-background`
- `--krypt-surface`

Theme changes are applied through the shared Flutter theme layer. Enabling or disabling a plugin causes the application theme to rebuild without changing playback state, playlists, downloads or account data.

Unknown CSS properties are ignored. Values are length-limited and only `--krypt-*` declarations are accepted by the current parser.

### Persistent Plugin State

Installed plugin metadata is saved in the application documents directory under the KRYPT plugin storage directory. The app persists:

- Plugin manifest metadata.
- Plugin installation directory.
- Enabled or disabled state.

Plugin files are stored outside the Flutter asset bundle, so users can install, disable or remove plugins without replacing the application binary.

### Built-in Authoring Guide

V1.0.1 adds a built-in guide available from the Plugin Marketplace. The guide explains:

- What a `.kryptplugin` package is.
- The required package layout.
- How to create `manifest.json`.
- How to create `theme.css`.
- Supported KRYPT theme tokens.
- The role of `plugin.js`.
- How to publish a plugin to a GitHub marketplace branch.
- Permission and safety expectations.

The guide is intended to provide a starting point for community authors without requiring them to inspect the application source code first.

---

## Initial Marketplace Plugin

The `plugins` branch includes an example theme package:

### Neon Glass

- **ID:** `neon-glass`
- **Version:** `1.0.0`
- **Author:** Synapse Labs UK Ltd
- **Type:** Theme-only plugin
- **Permissions:** None
- **Style:** Violet, electric-blue and dark glass surfaces

Package location:

```text
marketplace/packages/neon-glass.kryptplugin
```

The marketplace branch also includes:

```text
marketplace/index.json
marketplace/neon-glass-manifest.json
```

---

## JavaScript Runtime Status

The `.kryptplugin` format includes a JavaScript entry point so that the package format can support future event-driven plugins. Example hooks are documented in the in-app guide:

```javascript
export function onActivate(krypt) {
  krypt.ui.toast("Theme active");
}

export function onSongChanged(song) {
  // React to a playback event when the hook is available.
}
```

For safety, V1.0.1 does **not** execute arbitrary marketplace JavaScript with unrestricted native access. This avoids exposing the following capabilities to untrusted downloaded code:

- Local filesystem access.
- Application database access.
- Credentials or authentication state.
- Unrestricted network access.
- Direct audio-player control.
- Native platform APIs.
- Arbitrary Flutter method invocation.

A future release can add a sandboxed JavaScript runtime with explicit capability permissions and a narrow event API. The manifest already includes a permissions field to support that future boundary.

---

## Permissions Foundation

Plugin manifests may declare permissions such as:

```json
"permissions": [
  "network",
  "player",
  "navigation"
]
```

The permission values are retained and displayed as part of the plugin metadata model. Theme-only packages should use an empty permission list:

```json
"permissions": []
```

Authors should request only capabilities their plugin genuinely needs. Users should review permissions and install packages only from sources they trust.

---

## User Workflow

### Open the Marketplace

1. Open KRYPT AUDIO.
2. Open **Settings**.
3. Select **Plugin Marketplace**.
4. Press the refresh button if the marketplace list needs updating.

### Install a Plugin

1. Select a compatible plugin.
2. Review the displayed name, version, description and author.
3. Press **Install**.
4. KRYPT AUDIO downloads and validates the `.kryptplugin` package.
5. The plugin appears in the Installed section.
6. Its theme is enabled after installation when applicable.

### Disable or Uninstall a Plugin

1. Open **Settings → Plugin Marketplace**.
2. Open the action menu for an installed plugin.
3. Select **Disable** to keep its files but stop applying it.
4. Select **Uninstall** to remove the plugin from app storage.

---

## Developer Workflow

To publish a plugin:

1. Create a package directory containing `manifest.json`, `plugin.js` and `theme.css`.
2. Zip the directory contents.
3. Rename the resulting archive with the `.kryptplugin` extension.
4. Upload the package to the marketplace branch.
5. Add a matching manifest object to `marketplace/index.json`.
6. Use a raw GitHub HTTPS URL for `downloadUrl`.
7. Set `minAppVersion` to the earliest KRYPT version that supports the plugin.
8. Test installation, enable, disable and uninstall behaviour.

The marketplace manifest and package IDs must match exactly.

---

## Core Functionality Preserved

This release is additive. The following existing functionality remains in the application:

- Music playback.
- Search and suggestions.
- Playlists and playlist folders.
- Downloads and offline playback.
- Lyrics.
- Equaliser.
- Radio stations.
- Listening statistics.
- SponsorBlock support.
- Data backup and restore.
- Existing settings and theme controls.
- KRYPT AUDIO navigation and mini-player.
- PayPal donation flow.
- Synapse Labs and Telegram links.

No music backend, playback service, media database or download service was replaced as part of the plugin release.

---

## Android Build Information

```text
Application: KRYPT AUDIO
Version name: 1.0.1
Version code: 2
Application ID: com.synapselabs.kryptaudio
Target: Android ARM64
Build type: Release
Artifact: KRYPT-AUDIO-V1.0.1.apk
```

The release APK was built from the V1.0.1 source with a temporary local signing key for testing and distribution in this workspace. The temporary keystore was removed and was not committed to the repository.

APK SHA-256:

```text
4c75b588eab5083bdd050c2733a6d44d78d196c1c7f0cf2cb8c73d0699e1916f
```

The APK was verified with Android APK Signature Scheme v2.

---

## Compatibility and Migration

V1.0.1 is designed as an in-place update from V1.0.0. Existing playback and user data are retained through the existing application storage and Hive databases.

On first startup, KRYPT AUDIO creates its plugin storage directory if it does not already exist. Users with no installed plugins will see an empty Installed section and can continue using the application normally.

No migration is required for users who do not use plugins.

---

## Known Limitations

- V1.0.1 supports Android plugin installation and theme token application; desktop and iOS packaging require separate platform validation.
- The marketplace currently depends on GitHub availability and the configured `plugins` branch.
- Packages are downloaded over HTTPS, but publisher signature verification is not yet implemented.
- The marketplace does not yet show cryptographic checksums or publisher trust badges.
- JavaScript entry points are packaged and validated but are not yet executed with native app access.
- Only the documented `--krypt-*` theme tokens are applied.
- Plugin update notifications are not yet implemented; users can refresh the marketplace manually.
- Plugin dependency resolution is not yet supported.
- A plugin can currently be enabled or disabled, but there is no per-plugin settings editor yet.
- The current marketplace is a GitHub branch rather than a dedicated hosted registry.

---

## Security Notes

Users should treat community plugins as third-party software. Install packages only from authors and repositories they trust.

The current release reduces risk by:

- Validating manifests.
- Enforcing app-version compatibility.
- Rejecting unsafe archive paths.
- Installing through a staging directory.
- Restricting active CSS parsing to approved KRYPT tokens.
- Not executing arbitrary downloaded JavaScript in the native Flutter process.
- Preserving declared permissions for future capability enforcement.

The recommended next security milestone is signed plugin manifests or package checksums combined with a sandboxed JavaScript runtime.

---

## Repository Changes

The V1.0.1 source release includes:

- `lib/models/plugin_manifest.dart`
- `lib/services/plugin_service.dart`
- `lib/screens/plugin_marketplace_page.dart`
- `lib/screens/plugin_guide_page.dart`
- Plugin routes under Settings.
- Plugin-aware theme token application.
- `archive` dependency for `.kryptplugin` extraction.
- Application version `1.0.1+2`.
- Marketplace documentation and example package.

Main source commit:

```text
05ef73d — Add V1.0.1 plugin marketplace and theme system
```

Marketplace branch commit:

```text
975c146 — Publish initial KRYPT plugin marketplace
```

---

## Licensing and Attribution

KRYPT AUDIO retains the required GPL-3.0 licensing information and upstream attribution from the Musify project. Plugin authors may distribute their own plugin code under compatible terms, but the KRYPT AUDIO application remains distributed under the repository's GPL-3.0 license.

Plugin authors are responsible for the licensing, assets, code and external services included in their own packages. Third-party plugin content is not automatically endorsed by Synapse Labs UK Ltd.

---

## Credits

KRYPT AUDIO is branded and developed by **Synapse Labs UK Ltd**.

The application retains upstream Musify attribution and GPL-3.0 licensing information as required by the original project and its license.
