/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     KRYPT AUDIO plugin support for the Musify upstream project.
 *     Distributed under the GNU General Public License version 3.
 */

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:musify/constants/version.dart';
import 'package:musify/models/plugin_manifest.dart';

/// The marketplace branch should contain an index.json and one package per
/// plugin. Packages use the custom .kryptplugin extension but are ZIP files.
const pluginMarketplaceIndexUrl =
    'https://raw.githubusercontent.com/KRYPT-AUDIO/KRYPT_AUDIO_SOURCE/main/plugins/index.json';

class KryptPluginService extends ChangeNotifier {
  KryptPluginService._();

  static final KryptPluginService instance = KryptPluginService._();

  Directory? _root;
  final Map<String, InstalledKryptPlugin> _installed = {};
  Map<String, String> _themeTokens = const {};
  Set<String> _runtimeFeatures = const {};
  Set<String> _homeBadges = const {};
  String _playerMode = 'standard';
  String _motionPreset = 'standard';

  List<InstalledKryptPlugin> get installed =>
      _installed.values.toList(growable: false);
  Map<String, String> get themeTokens => _themeTokens;
  Set<String> get runtimeFeatures => _runtimeFeatures;
  Set<String> get homeBadges => _homeBadges;
  String get playerMode => _playerMode;
  String get motionPreset => _motionPreset;

  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _root = Directory('${directory.path}/krypt_plugins');
    await _root!.create(recursive: true);
    await _loadInstalled();
  }

  Future<List<KryptPluginManifest>> fetchMarketplace() async {
    final response = await http.get(Uri.parse(pluginMarketplaceIndexUrl));
    if (response.statusCode != 200) {
      throw HttpException('Marketplace returned ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List)
      throw const FormatException('Marketplace index must be a JSON array');
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(KryptPluginManifest.fromJson)
        .where((plugin) => _isCompatible(plugin.minAppVersion))
        .toList(growable: false);
  }

  Future<void> install(KryptPluginManifest manifest) async {
    _ensureInitialized();
    final response = await http.get(Uri.parse(manifest.downloadUrl));
    if (response.statusCode != 200) {
      throw HttpException('Plugin download returned ${response.statusCode}');
    }

    final archive = ZipDecoder().decodeBytes(response.bodyBytes, verify: true);
    final staging = Directory('${_root!.path}/.${manifest.id}.staging');
    final destination = Directory('${_root!.path}/${manifest.id}');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final relative = _safeRelativePath(file.name);
        final output = File('${staging.path}/$relative');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(file.content as List<int>, flush: true);
      }
      final manifestFile = File('${staging.path}/manifest.json');
      if (!await manifestFile.exists())
        throw const FormatException('Package has no manifest.json');
      final installedManifest = KryptPluginManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
      );
      if (installedManifest.id != manifest.id) {
        throw const FormatException('Package id does not match marketplace id');
      }
      _validateEntry(staging, installedManifest.entryScript);
      _validateEntry(staging, installedManifest.stylesheet);
      if (await destination.exists()) await destination.delete(recursive: true);
      await staging.rename(destination.path);
      _installed[manifest.id] = InstalledKryptPlugin(
        manifest: installedManifest,
        directoryPath: destination.path,
        enabled: true,
      );
      await _persistInstalled();
      await applyEnabledThemes();
      notifyListeners();
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final plugin = _installed[id];
    if (plugin == null) return;
    _installed[id] = InstalledKryptPlugin(
      manifest: plugin.manifest,
      directoryPath: plugin.directoryPath,
      enabled: enabled,
    );
    await _persistInstalled();
    await applyEnabledThemes();
    notifyListeners();
  }

  Future<void> uninstall(String id) async {
    final plugin = _installed.remove(id);
    if (plugin != null) {
      final directory = Directory(plugin.directoryPath);
      if (await directory.exists()) await directory.delete(recursive: true);
      await _persistInstalled();
      await applyEnabledThemes();
      notifyListeners();
    }
  }

  Future<String> readScript(InstalledKryptPlugin plugin) async {
    final file = File('${plugin.directoryPath}/${plugin.manifest.entryScript}');
    return file.existsSync() ? file.readAsString() : '';
  }

  Future<void> applyEnabledThemes() async {
    final tokens = <String, String>{};
    for (final plugin in _installed.values.where((item) => item.enabled)) {
      final stylesheet = File(
        '${plugin.directoryPath}/${plugin.manifest.stylesheet}',
      );
      if (!await stylesheet.exists()) continue;
      tokens.addAll(_parseThemeTokens(await stylesheet.readAsString()));
    }
    _themeTokens = Map.unmodifiable(tokens);
    await _runSafeHooks();
  }

  Future<void> _runSafeHooks() async {
    final features = <String>{};
    final badges = <String>{};
    var playerMode = 'standard';
    var motionPreset = 'standard';
    final capabilityPattern = RegExp(r'''capability:\s*['"]([^'"]+)''');
    final featurePattern = RegExp(r'''api\.enableFeature\(['"]([^'"]+)''');
    final badgePattern = RegExp(r'''api\.addHomeBadge\(['"]([^'"]+)''');
    for (final plugin in _installed.values.where((item) => item.enabled)) {
      final script = await readScript(plugin);
      final capability = capabilityPattern.firstMatch(script)?.group(1);
      if (capability != null) features.add(capability);
      features.addAll(
        featurePattern.allMatches(script).map((m) => m.group(1)!),
      );
      badges.addAll(badgePattern.allMatches(script).map((m) => m.group(1)!));
      if (script.contains('api.setPlayerMode')) playerMode = 'enhanced';
      if (script.contains('api.setMotionPreset')) motionPreset = 'smooth';
    }
    _runtimeFeatures = Set.unmodifiable(features);
    _homeBadges = Set.unmodifiable(badges);
    _playerMode = playerMode;
    _motionPreset = motionPreset;
  }

  Map<String, String> _parseThemeTokens(String css) {
    final tokens = <String, String>{};
    final block =
        RegExp(
          r':root\s*\{([^}]*)\}',
          dotAll: true,
        ).firstMatch(css)?.group(1) ??
        css;
    for (final declaration in block.split(';')) {
      final parts = declaration.split(':');
      if (parts.length < 2) continue;
      final key = parts.first.trim();
      final value = parts.sublist(1).join(':').trim();
      if (key.startsWith('--krypt-') && value.length <= 120)
        tokens[key] = value;
    }
    return tokens;
  }

  Future<void> _loadInstalled() async {
    final file = File('${_root!.path}/installed.json');
    if (!await file.exists()) return;
    final values = jsonDecode(await file.readAsString());
    if (values is! List) return;
    for (final value in values.whereType<Map<String, dynamic>>()) {
      try {
        final manifest = KryptPluginManifest.fromJson(
          value['manifest'] as Map<String, dynamic>,
        );
        final path = value['directoryPath'] as String;
        if (await Directory(path).exists()) {
          _installed[manifest.id] = InstalledKryptPlugin(
            manifest: manifest,
            directoryPath: path,
            enabled: value['enabled'] == true,
          );
        }
      } catch (_) {}
    }
    await applyEnabledThemes();
  }

  Future<void> _persistInstalled() async {
    final file = File('${_root!.path}/installed.json');
    await file.writeAsString(
      jsonEncode(
        _installed.values
            .map(
              (plugin) => {
                'manifest': {
                  'id': plugin.manifest.id,
                  'name': plugin.manifest.name,
                  'version': plugin.manifest.version,
                  'description': plugin.manifest.description,
                  'author': plugin.manifest.author,
                  'minAppVersion': plugin.manifest.minAppVersion,
                  'entryScript': plugin.manifest.entryScript,
                  'stylesheet': plugin.manifest.stylesheet,
                  'permissions': plugin.manifest.permissions,
                  'downloadUrl': plugin.manifest.downloadUrl,
                  'iconUrl': plugin.manifest.iconUrl,
                  'repositoryUrl': plugin.manifest.repositoryUrl,
                },
                'directoryPath': plugin.directoryPath,
                'enabled': plugin.enabled,
              },
            )
            .toList(),
      ),
    );
  }

  bool _isCompatible(String minimum) =>
      _compareVersions(appVersion, minimum) >= 0;

  void _validateEntry(Directory root, String relativePath) {
    final safe = _safeRelativePath(relativePath);
    if (!File('${root.path}/$safe').existsSync()) {
      throw FormatException('Package is missing $relativePath');
    }
  }

  String _safeRelativePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('/') || normalized.split('/').contains('..')) {
      throw const FormatException('Unsafe plugin path');
    }
    return normalized;
  }

  void _ensureInitialized() {
    if (_root == null)
      throw StateError('KryptPluginService has not been initialized');
  }

  int _compareVersions(String left, String right) {
    final a = left.split('.').map((value) => int.tryParse(value) ?? 0).toList();
    final b = right
        .split('.')
        .map((value) => int.tryParse(value) ?? 0)
        .toList();
    for (
      var index = 0;
      index < (a.length > b.length ? a.length : b.length);
      index++
    ) {
      final comparison = (index < a.length ? a[index] : 0).compareTo(
        index < b.length ? b[index] : 0,
      );
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

@visibleForTesting
String safePluginPathForTest(String path) =>
    KryptPluginService.instance._safeRelativePath(path);
