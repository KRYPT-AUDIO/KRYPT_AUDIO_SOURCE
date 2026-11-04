const List<Map<String, dynamic>> kryptWebCatalog = [
  {'ytid': '4NRXx6U8ABQ', 'title': 'Blinding Lights', 'artist': 'The Weeknd'},
  {'ytid': '5NV6Rdv1a3I', 'title': 'Get Lucky', 'artist': 'Daft Punk'},
  {'ytid': 'DyDfgMOUjCI', 'title': 'bad guy', 'artist': 'Billie Eilish'},
  {'ytid': 'TUVcZfQe-Kw', 'title': 'Levitating', 'artist': 'Dua Lipa'},
  {'ytid': 'dvgZkm1xWPE', 'title': 'Viva La Vida', 'artist': 'Coldplay'},
  {'ytid': '7wtfhZwyrcc', 'title': 'Believer', 'artist': 'Imagine Dragons'},
  {'ytid': 'JGwWNGJdvx8', 'title': 'Shape of You', 'artist': 'Ed Sheeran'},
  {'ytid': 'wXhTHyIgQ_U', 'title': 'Circles', 'artist': 'Post Malone'},
  {'ytid': '2vjPBrBU-TM', 'title': 'Chandelier', 'artist': 'Sia'},
  {'ytid': 'OPf0YbXqDm0', 'title': 'Uptown Funk', 'artist': 'Mark Ronson'},
  {'ytid': 'ZbZSe6N_BXs', 'title': 'Happy', 'artist': 'Pharrell Williams'},
  {'ytid': '09R8_2nJtjg', 'title': 'Sugar', 'artist': 'Maroon 5'},
  {'ytid': 'IcrbM1l_BoI', 'title': 'Wake Me Up', 'artist': 'Avicii'},
  {'ytid': 'kXYiU_JCYtU', 'title': 'Numb', 'artist': 'Linkin Park'},
  {'ytid': 'fJ9rUzIMcZQ', 'title': 'Bohemian Rhapsody', 'artist': 'Queen'},
  {'ytid': 'Zi_XlobLjfI', 'title': 'Billie Jean', 'artist': 'Michael Jackson'},
  {'ytid': 'bESGLojNYSo', 'title': 'Poker Face', 'artist': 'Lady Gaga'},
  {'ytid': 'QGJuMBdaqIw', 'title': 'Firework', 'artist': 'Katy Perry'},
  {'ytid': 'ebXbLfLACGM', 'title': 'Summer', 'artist': 'Calvin Harris'},
  {'ytid': 'YqeW9_5kURI', 'title': 'Lean On', 'artist': 'Major Lazer'},
];

Map<String, dynamic> kryptWebCatalogSong(
  Map<String, dynamic> source,
  int index, {
  String? image,
}) {
  final id = source['ytid'].toString();
  final artwork = image ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  return {
    ...source,
    'artistId': null,
    'videoAuthor': source['artist'],
    'image': artwork,
    'lowResImage': artwork,
    'highResImage': artwork,
    'duration': null,
    'isLive': false,
    'source': 'krypt-web-catalog',
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
      .where((song) =>
          '${song['title']} ${song['artist']}'.toLowerCase().contains(normalized))
      .toList();
  return [
    for (var i = 0; i < matches.length; i++) kryptWebCatalogSong(matches[i], i),
  ];
}

List<Map<String, dynamic>> kryptCatalogPlaylists() => [
      {
        'ytid': 'web:krypt-pulse',
        'title': 'KRYPT Pulse',
        'description': 'The essential KRYPT AUDIO rotation.',
        'image': 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
        'isAlbum': false,
        'source': 'krypt-web-catalog',
        'list': kryptCatalogSongs(),
      },
      {
        'ytid': 'web:krypt-afterdark',
        'title': 'KRYPT Afterdark',
        'description': 'Late-night neon frequencies.',
        'image': 'https://i.ytimg.com/vi/5NV6Rdv1a3I/hqdefault.jpg',
        'isAlbum': false,
        'source': 'krypt-web-catalog',
        'list': kryptCatalogSongs().reversed.take(10).toList(),
      },
      {
        'ytid': 'web:krypt-classics',
        'title': 'KRYPT Classics',
        'description': 'Permanent signals from the archive.',
        'image': 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
        'isAlbum': false,
        'source': 'krypt-web-catalog',
        'list': kryptCatalogSongs().skip(10).toList(),
      },
    ];
