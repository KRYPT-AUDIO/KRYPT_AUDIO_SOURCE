/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/account_service.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/desktop_media_artwork.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/linux_media_controls.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/playlist_sharing.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/plugin_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/spotify_service.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/services/windows_media_controls.dart';
import 'package:musify/theme/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/language_utils.dart';
import 'package:musify/utilities/platform_utils.dart';
import 'package:musify/utilities/playlist_utils.dart';
import 'package:musify/utilities/sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

late MusifyAudioHandler audioHandler;
LinuxMediaControls? linuxMediaControls;
WindowsMediaControls? windowsMediaControls;
StreamSubscription<String?>? sharingIntentSubscription;
StreamSubscription<Uri?>? appLinksSubscription;

final logger = Logger();
final appLinks = AppLinks();

bool isFdroidBuild = false;
bool isUpdateChecked = false;

class Musify extends StatefulWidget {
  const Musify({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? useSystemColor,
  }) async {
    context.findAncestorStateOfType<_MusifyState>()!.changeSettings(
      newThemeMode: newThemeMode,
      newLocale: newLocale,
      newAccentColor: newAccentColor,
      systemColorStatus: useSystemColor,
    );
  }

  @override
  _MusifyState createState() => _MusifyState();
}

class _MusifyState extends State<Musify> with WidgetsBindingObserver {
  bool _showBootSplash = true;

  void changeSettings({
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? systemColorStatus,
  }) {
    setState(() {
      if (newThemeMode != null) {
        themeMode = newThemeMode;
        brightness = getBrightnessFromThemeMode(newThemeMode);
      }
      if (newLocale != null) {
        languageSetting = newLocale;
      }
      if (newAccentColor != null) {
        if (systemColorStatus != null &&
            useSystemColor.value != systemColorStatus) {
          useSystemColor.value = systemColorStatus;
          addOrUpdateData<bool>(
            'settings',
            'useSystemColor',
            systemColorStatus,
          );
        }
        primaryColorSetting = newAccentColor;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Keep the branded boot surface visible long enough to be perceptible even
    // when the native Android launch window is removed immediately after the
    // first Flutter frame.
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showBootSplash = false);
    });

    WidgetsBinding.instance.addObserver(this);

    if (isMobilePlatform) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    final platformDispatcher = PlatformDispatcher.instance;

    // This callback is called every time the brightness changes.
    platformDispatcher.onPlatformBrightnessChanged = () {
      if (themeMode == ThemeMode.system) {
        setState(() {
          brightness = platformDispatcher.platformBrightness;
        });
      }
    };

    offlineMode.addListener(_onOfflineModeChanged);

    if (isMobilePlatform) {
      sharingIntentSubscription = ReceiveSharingIntent.getTextStream().listen(
        (String? value) async {
          await consumeYoutubeSharedTextIntent(
            value,
            audioHandler: audioHandler,
            onError: (error, stackTrace) {
              logger.log(
                'Error while playing shared song:',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
        },
        onError: (err) {
          logger.log('getTextStream error:', error: err);
        },
      );
    }

    try {
      LicenseRegistry.addLicense(() async* {
        final license = await rootBundle.loadString(
          'assets/licenses/paytone.txt',
        );
        yield LicenseEntryWithLineBreaks(['paytoneOne'], license);
      });
    } catch (e, stackTrace) {
      logger.log(
        'License Registration Error',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!isFdroidBuild && isMobilePlatform) {
      if (shouldWeCheckUpdates.value == true) {
        if (!isUpdateChecked && kReleaseMode) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!offlineMode.value) {
              checkAppUpdates();
            }
            isUpdateChecked = true;
          });
        }
      } else {
        if (shouldWeCheckUpdates.value == null) {
          // show dialog that asks user if they want to enable update checks
          SchedulerBinding.instance.addPostFrameCallback((_) {
            showUpdateCheckDialog(NavigationManager().context);
          });
        } else {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (!offlineMode.value) {
              await fetchAnnouncementOnly();
            }
          });
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Persist listening stats when the app leaves the foreground. This is the
    // reliable moment to snapshot and flush: unlike widget dispose, these
    // callbacks are delivered before the OS suspends or terminates the process.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      listeningStatsService.recordListeningSessionProgress(
        wasPlaying: audioHandler.audioPlayer.playing,
      );
      unawaited(listeningStatsService.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    offlineMode.removeListener(_onOfflineModeChanged);
    PlatformDispatcher.instance.onPlatformBrightnessChanged = null;

    unawaited(linuxMediaControls?.dispose());
    unawaited(windowsMediaControls?.dispose());
    Hive.close();
    unawaited(sharingIntentSubscription?.cancel());
    unawaited(appLinksSubscription?.cancel());
    super.dispose();
  }

  void _onOfflineModeChanged() {
    // Force rebuild when offline mode changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: KryptPluginService.instance,
      builder: (context, _) => DynamicColorBuilder(
        builder: (lightColorScheme, darkColorScheme) {
          final colorScheme = getAppColorScheme(
            lightColorScheme,
            darkColorScheme,
          );

          final app = AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: true,
              statusBarBrightness: brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarIconBrightness: brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarIconBrightness: brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: MaterialApp.router(
              themeMode: themeMode,
              darkTheme: getAppTheme(colorScheme),
              theme: getAppTheme(colorScheme),
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: appSupportedLocales,
              locale: languageSetting,
              routerConfig: NavigationManager.router,
            ),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              app,
              IgnorePointer(
                ignoring: !_showBootSplash,
                child: AnimatedOpacity(
                  opacity: _showBootSplash ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  child: const _KryptBootSplash(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KryptBootSplash extends StatelessWidget {
  const _KryptBootSplash();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050816),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash/krypt_audio_splash.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050816).withValues(alpha: .18),
                  const Color(0xFF050816).withValues(alpha: .08),
                  const Color(0xFF050816).withValues(alpha: .82),
                ],
                stops: const [0, .54, 1],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 42),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'KRYPT AUDIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'paytoneOne',
                        fontSize: 26,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'INITIALISING THE FREQUENCY',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 92,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: Colors.white.withValues(alpha: .18),
                        color: const Color(0xFF9C7BFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialisation();

  runApp(const Musify());
}

Future<void> initialisation() async {
  try {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('user'),
      Hive.openBox('userNoBackup'),
      Hive.openBox('cache'),
    ]);
    await KryptPluginService.instance.initialize();
    await KryptAccountService.instance.restore();
    await SpotifyService.instance.restore();

    if (isMobilePlatform) {
      audioHandler = await AudioService.init(
        builder: MusifyAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.synapselabs.kryptaudio',
          androidNotificationChannelName: 'KRYPT AUDIO',
          androidNotificationIcon: 'drawable/ic_launcher_foreground',
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: false,
          // Handed to Android Auto on the browsable root. Without the search
          // flag the car never offers a search box, and without the content
          // style keys it falls back to an undifferentiated list of everything.
          androidBrowsableRootExtras: {
            AndroidContentStyle.supportedKey: true,
            AndroidContentStyle.browsableHintKey:
                AndroidContentStyle.gridItemHintValue,
            AndroidContentStyle.playableHintKey:
                AndroidContentStyle.listItemHintValue,
            'android.media.browse.SEARCH_SUPPORTED': true,
          },
        ),
      );
    } else {
      // Use the desktop audio backend without mobile service plugins.
      JustAudioMediaKit.title = 'KRYPT AUDIO';
      JustAudioMediaKit.ensureInitialized();
      audioHandler = MusifyAudioHandler();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final artwork = DesktopMediaArtwork();
      final controls = WindowsMediaControls(
        canGoNext: () => audioHandler.canSkipToNext,
        canGoPrevious: () => audioHandler.hasPrevious,
        navigationChanges: Listenable.merge([
          repeatNotifier,
          playNextSongAutomatically,
          offlineMode,
        ]),
        resolveArtwork: artwork.resolve,
        onError: (error, stackTrace) => logger.log(
          'Windows media controls error',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      try {
        await controls.start(audioHandler);
        windowsMediaControls = controls;
      } catch (error, stackTrace) {
        logger.log(
          'Could not initialize Windows media controls',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      final artwork = DesktopMediaArtwork();
      final controls = LinuxMediaControls(
        handler: audioHandler,
        skipToNext: () => audioHandler.skipToNext(
          playWhenReady: audioHandler.shouldContinuePlayback,
        ),
        skipToPrevious: () => audioHandler.skipToPrevious(
          playWhenReady: audioHandler.shouldContinuePlayback,
        ),
        resolveArtwork: artwork.resolve,
        volume: () => audioHandler.volume,
        volumeStream: audioHandler.volumeStream,
        setVolume: audioHandler.setVolume,
        canGoNext: () => audioHandler.canSkipToNext,
        navigationChanges: Listenable.merge([
          repeatNotifier,
          playNextSongAutomatically,
          offlineMode,
        ]),
        canGoPrevious: () => audioHandler.hasPrevious,
        raise: () =>
            const MethodChannel('musify/window').invokeMethod<void>('raise'),
        position: () => audioHandler.currentPositionData.position,
        onError: (error, stackTrace) => logger.log(
          'Linux media controls error',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      try {
        await controls.start();
        linuxMediaControls = controls;
      } catch (error, stackTrace) {
        logger.log(
          'Could not initialize Linux media controls',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Init router
    NavigationManager.instance;

    try {
      // Listen to incoming links while app is running
      appLinksSubscription = appLinks.uriLinkStream.listen(
        handleIncomingLink,
        onError: (err) {
          logger.log('URI link error:', error: err);
        },
      );
      await handleIncomingLink(await appLinks.getInitialLink());
    } on PlatformException {
      logger.log('Failed to get initial uri');
    }

    if (isFdroidBuild && !offlineMode.value) {
      await fetchAnnouncementOnly();
    }
  } catch (e, stackTrace) {
    logger.log('Initialization Error', error: e, stackTrace: stackTrace);
  }

  applicationDirPath = (await getApplicationDocumentsDirectory()).path;
  await FilePaths.ensureDirectoriesExist();
}

Future<void> handleIncomingLink(Uri? uri) async {
  if (uri != null && await SpotifyService.instance.handleCallback(uri)) return;
  if (uri == null || uri.scheme != 'musify' || uri.host != 'playlist') return;

  if (uri.pathSegments.length < 2 || uri.pathSegments[0] != 'custom') return;

  try {
    final encodedPlaylist = uri.pathSegments[1];
    final playlist = await PlaylistSharingService.decodeAndExpandPlaylist(
      encodedPlaylist,
    );

    if (playlist == null) {
      _showPlaylistError();
      return;
    }

    // Ensure the incoming playlist has a unique id so it can be removed later
    if (playlist['ytid'] == null || playlist['ytid'].toString().isEmpty) {
      playlist['ytid'] = PlaylistUtils.generateCustomPlaylistId();
    }

    // Check for duplicate by title and song ytids
    final incomingYtids = (playlist['list'] as List<dynamic>)
        .map((s) => s['ytid'].toString())
        .toList();

    final isDuplicate = PlaylistUtils.playlistExists(
      playlist,
      incomingYtids,
      userCustomPlaylists.value,
    );

    if (isDuplicate) {
      showToast(
        NavigationManager().context,
        NavigationManager().context.l10n!.playlistAlreadyExists,
      );
    } else {
      userCustomPlaylists.value = [...userCustomPlaylists.value, playlist];
      unawaited(
        addOrUpdateData<List>(
          'user',
          'customPlaylists',
          userCustomPlaylists.value,
        ),
      );
      showToast(
        NavigationManager().context,
        '${NavigationManager().context.l10n!.addedSuccess}!',
      );
    }
  } catch (e) {
    _showPlaylistError();
  }
}

void _showPlaylistError() {
  showToast(
    NavigationManager().context,
    NavigationManager().context.l10n!.failedToLoadPlaylist,
  );
}
