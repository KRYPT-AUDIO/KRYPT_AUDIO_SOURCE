class SpotifyWebService {
  SpotifyWebService._();
  static final instance = SpotifyWebService._();

  bool get configured => false;
  bool get authenticated => false;
  bool get isAuthenticated => false;

  Future<void> initialize() async {}
  Future<bool> login() async => false;
  Future<bool> logout() async => false;
  Future<List<Map<String, dynamic>>> searchTracks(String query) async => [];
  Future<bool> playTrack(String spotifyTrackId) async => false;
  Future<bool> pause() async => false;
}
