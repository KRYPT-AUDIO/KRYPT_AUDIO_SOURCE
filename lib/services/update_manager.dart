/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     KRYPT AUDIO updater enhancements are distributed under GPL-3.0.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/platform_utils.dart';
import 'package:musify/widgets/auto_format_text.dart';

const String githubReleasesUrl =
    'https://api.github.com/repos/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/releases/latest';
const String githubReleasesPageUrl =
    'https://github.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/releases/latest';
const String checkUrl =
    'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json';

const _apkInstallerChannel = MethodChannel('krypt_audio/apk_installer');

class GithubRelease {
  const GithubRelease({
    required this.version,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.assetName,
    required this.publishedAt,
  });

  final String version;
  final String name;
  final String body;
  final String downloadUrl;
  final String assetName;
  final DateTime? publishedAt;
}

Future<void> checkAppUpdates() async {
  if (!isAndroidPlatform || offlineMode.value) return;

  try {
    final release = await fetchLatestGithubRelease();
    if (release == null ||
        !isLatestVersionHigher(appVersion, release.version)) {
      return;
    }

    final context = NavigationManager().context;
    if (!context.mounted) return;
    await showGithubUpdateDialog(context, release);
  } catch (error, stackTrace) {
    logger.log(
      'Error checking KRYPT AUDIO GitHub releases',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Runs the update check from Settings and always gives the user a result.
/// Automatic background checks intentionally stay quiet when no update exists;
/// a manually requested check should never appear to do nothing.
Future<void> checkForUpdatesManually(BuildContext context) async {
  if (!isAndroidPlatform) {
    showToast(context, 'Updates are available from Android releases.');
    return;
  }
  if (offlineMode.value) {
    showToast(context, 'Connect to the internet to check for updates.');
    return;
  }

  showToast(context, 'Checking GitHub for updates…');
  try {
    final release = await fetchLatestGithubRelease();
    if (!context.mounted) return;
    if (release == null) {
      showToast(context, 'No downloadable Android release was found.');
      return;
    }
    if (isLatestVersionHigher(appVersion, release.version)) {
      await showGithubUpdateDialog(context, release);
    } else {
      showToast(context, 'KRYPT AUDIO is up to date ($appVersion).');
    }
  } catch (error, stackTrace) {
    logger.log(
      'Manual KRYPT AUDIO update check failed',
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      showToast(context, 'Could not check GitHub releases. Try again later.');
    }
  }
}

Future<GithubRelease?> fetchLatestGithubRelease() async {
  final response = await http.get(
    Uri.parse(githubReleasesUrl),
    headers: const {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  );
  if (response.statusCode != 200) {
    logger.log('GitHub releases request returned ${response.statusCode}');
    return null;
  }

  final json = jsonDecode(response.body);
  if (json is! Map<String, dynamic>) return null;
  if (json['draft'] == true || json['prerelease'] == true) return null;

  final version = _normaliseVersion(json['tag_name']?.toString() ?? '');
  if (version.isEmpty) return null;

  final assets = (json['assets'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .where((asset) => asset['browser_download_url'] is String)
      .where((asset) => asset['name'].toString().toLowerCase().endsWith('.apk'))
      .toList(growable: false);
  if (assets.isEmpty) {
    logger.log('Latest GitHub release $version has no APK asset');
    return null;
  }

  final selected = _selectApkAsset(assets);
  return GithubRelease(
    version: version,
    name: (json['name']?.toString().trim().isNotEmpty ?? false)
        ? json['name'].toString()
        : 'KRYPT AUDIO $version',
    body: json['body']?.toString() ?? 'No release notes were provided.',
    downloadUrl: selected['browser_download_url'].toString(),
    assetName: selected['name'].toString(),
    publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
  );
}

Map<String, dynamic> _selectApkAsset(List<Map<String, dynamic>> assets) {
  final arm64 = assets
      .where((asset) {
        final name = asset['name'].toString().toLowerCase();
        return name.contains('arm64') ||
            name.contains('aarch64') ||
            name.contains('universal');
      })
      .toList(growable: false);
  return (arm64.isNotEmpty ? arm64 : assets).first;
}

Future<void> showGithubUpdateDialog(
  BuildContext context,
  GithubRelease release,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _GithubUpdateDialog(release: release),
  );
}

class _GithubUpdateDialog extends StatefulWidget {
  const _GithubUpdateDialog({required this.release});

  final GithubRelease release;

  @override
  State<_GithubUpdateDialog> createState() => _GithubUpdateDialogState();
}

class _GithubUpdateDialogState extends State<_GithubUpdateDialog> {
  double? _progress;
  bool _downloading = false;
  String? _error;

  Future<void> _downloadAndInstall() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final request = http.Request(
        'GET',
        Uri.parse(widget.release.downloadUrl),
      );
      final response = await request.send();
      if (response.statusCode != 200) {
        throw HttpException('GitHub returned HTTP ${response.statusCode}');
      }

      final total = response.contentLength;
      var received = 0;
      final chunks = <List<int>>[];
      await for (final chunk in response.stream) {
        chunks.add(chunk);
        received += chunk.length;
        if (mounted && total != null && total > 0) {
          setState(() => _progress = received / total);
        }
      }
      final bytes = <int>[];
      for (final chunk in chunks) {
        bytes.addAll(chunk);
      }

      final installed = await _apkInstallerChannel.invokeMethod<bool>(
        'installApk',
        {
          'fileName': widget.release.assetName,
          'bytes': Uint8List.fromList(bytes),
        },
      );
      if (installed != true) {
        throw StateError('Android did not open the package installer');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error, stackTrace) {
      logger.log(
        'Failed to download KRYPT AUDIO update',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('KRYPT AUDIO ${widget.release.version}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.arrow_download_24_filled,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.release.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_downloading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  _progress == null
                      ? 'Downloading update…'
                      : 'Downloading ${((_progress ?? 0) * 100).round()}%',
                ),
              ] else
                AutoFormatText(text: widget.release.body),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Update failed: $_error',
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'The APK will be downloaded and Android will ask you to approve the installation.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n!.cancel),
        ),
        FilledButton.icon(
          onPressed: _downloading ? null : _downloadAndInstall,
          icon: const Icon(FluentIcons.arrow_download_20_regular),
          label: Text(_error == null ? context.l10n!.download : 'Retry'),
        ),
      ],
    );
  }
}

void showUpdateCheckDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        FluentIcons.arrow_sync_circle_24_regular,
        color: colorScheme.primary,
        size: 40,
      ),
      title: Text(
        context.l10n!.checkForUpdates,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        context.l10n!.enableUpdateChecksDescription,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () {
            shouldWeCheckUpdates.value = false;
            addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', false);
            Navigator.of(context).pop();
          },
          child: Text(context.l10n!.no),
        ),
        FilledButton(
          onPressed: () {
            shouldWeCheckUpdates.value = true;
            addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', true);
            if (!isFdroidBuild && kReleaseMode && !offlineMode.value) {
              unawaited(checkAppUpdates());
              isUpdateChecked = true;
            }
            Navigator.of(context).pop();
          },
          child: Text(context.l10n!.yes),
        ),
      ],
    ),
  );
}

String _normaliseVersion(String value) {
  final cleaned = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final match = RegExp(r'\d+(?:\.\d+){0,3}').firstMatch(cleaned);
  return match?.group(0) ?? '';
}

bool isLatestVersionHigher(String current, String latest) {
  final a = _normaliseVersion(current)
      .split('.')
      .map((value) => int.tryParse(value) ?? 0)
      .toList();
  final b = _normaliseVersion(latest)
      .split('.')
      .map((value) => int.tryParse(value) ?? 0)
      .toList();
  final length = a.length > b.length ? a.length : b.length;
  for (var index = 0; index < length; index++) {
    final left = index < a.length ? a[index] : 0;
    final right = index < b.length ? b[index] : 0;
    if (right != left) return right > left;
  }
  return false;
}

/// Retained for compatibility with existing callers and F-Droid announcement flow.
Future<void> fetchAnnouncementOnly() async {
  try {
    final response = await http.get(Uri.parse(checkUrl));
    if (response.statusCode != 200) return;
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final announcement = map['announcementurl'];
    if (announcement != null) announcementURL.value = announcement.toString();
  } catch (error, stackTrace) {
    logger.log(
      'Error in fetchAnnouncementOnly',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
