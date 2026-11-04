import 'spotify_web_stub.dart'
    if (dart.library.html) 'spotify_web_impl.dart' as implementation;

final spotifyWebService = implementation.SpotifyWebService.instance;

String? spotifyTrackIdFromSong(Map song) {
  final explicit = song['spotifyId']?.toString();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final ytid = song['ytid']?.toString() ?? '';
  return ytid.startsWith('spotify:') ? ytid.substring(8) : null;
}
