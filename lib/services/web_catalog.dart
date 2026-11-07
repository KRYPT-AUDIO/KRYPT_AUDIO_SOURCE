const String _demoArtwork = 'asset:///assets/icons/krypt_audio_icon.png';
const String _demoAudio = 'krypt-demo-loop.wav';

const List<Map<String, dynamic>> kryptWebCatalog = [
  {
    'ytid': 'krptdemo001',
    'title': 'Night Drive',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo002',
    'title': 'Violet Signal',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo003',
    'title': 'Glass Horizon',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo004',
    'title': 'Afterglow',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo005',
    'title': 'Midnight Frequency',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo006',
    'title': 'Blue Hour',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo007',
    'title': 'Static Dreams',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo008',
    'title': 'Soft Reset',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo009',
    'title': 'Neon Coast',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo010',
    'title': 'Quiet City',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo011',
    'title': 'Last Light',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
  {
    'ytid': 'krptdemo012',
    'title': 'Open Sky',
    'artist': 'KRYPT Studio',
    'album': 'Signals After Dark',
  },
];

Map<String, dynamic> kryptWebCatalogSong(
  Map<String, dynamic> source,
  int index, {
  String? image,
}) {
  final artwork = image ?? _demoArtwork;
  return {
    ...source,
    'artistId': null,
    'videoAuthor': source['artist'],
    'image': artwork,
    'lowResImage': artwork,
    'highResImage': artwork,
    'duration': 32,
    'isLive': false,
    'source': 'krypt-web-demo',
    'demoAsset': _demoAudio,
    'position': index,
  };
}

List<Map<String, dynamic>> kryptCatalogSongs() => [
  for (var i = 0; i < kryptWebCatalog.length; i++)
    kryptWebCatalogSong(kryptWebCatalog[i], i),
];

List<Map<String, dynamic>> searchKryptCatalog(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return kryptCatalogSongs();
  final matches = kryptWebCatalog
      .where(
        (song) => '${song['title']} ${song['artist']} ${song['album']}'
            .toLowerCase()
            .contains(normalized),
      )
      .toList();
  return [
    for (var i = 0; i < matches.length; i++) kryptWebCatalogSong(matches[i], i),
  ];
}

List<Map<String, dynamic>> kryptCatalogPlaylists() => [
  {
    'ytid': 'web:krypt-pulse',
    'title': 'KRYPT Pulse',
    'description': 'A first listen to the KRYPT web demo.',
    'image': _demoArtwork,
    'isAlbum': false,
    'source': 'krypt-web-demo',
    'list': kryptCatalogSongs(),
  },
  {
    'ytid': 'web:krypt-afterdark',
    'title': 'KRYPT Afterdark',
    'description': 'Low-lit signals for the late hours.',
    'image': _demoArtwork,
    'isAlbum': false,
    'source': 'krypt-web-demo',
    'list': kryptCatalogSongs().reversed.take(6).toList(),
  },
  {
    'ytid': 'web:krypt-classics',
    'title': 'KRYPT Essentials',
    'description': 'A compact tour through the demo catalog.',
    'image': _demoArtwork,
    'isAlbum': false,
    'source': 'krypt-web-demo',
    'list': kryptCatalogSongs().take(6).toList(),
  },
];
