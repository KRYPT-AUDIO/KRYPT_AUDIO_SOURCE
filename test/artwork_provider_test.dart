import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/artwork_provider.dart';

void main() {
  setUp(ArtworkProvider.clearCache);

  test('reuses a cached provider for a repeated artwork path', () {
    final first = ArtworkProvider.get('assets/cover.png');
    final second = ArtworkProvider.get('assets/cover.png');

    expect(identical(first, second), isTrue);
  });

  test('evicts the least-recently-used entry when the cache is full', () {
    final oldest = ArtworkProvider.get('assets/oldest.png');
    for (var index = 0; index < ArtworkProvider.maxCacheEntries; index++) {
      ArtworkProvider.get('assets/cover-$index.png');
    }

    final reloaded = ArtworkProvider.get('assets/oldest.png');
    expect(identical(oldest, reloaded), isFalse);
  });

  test('retains a recently reused entry ahead of older entries', () {
    final recent = ArtworkProvider.get('assets/recent.png');
    for (var index = 0; index < ArtworkProvider.maxCacheEntries - 1; index++) {
      ArtworkProvider.get('assets/cover-$index.png');
    }

    final touched = ArtworkProvider.get('assets/recent.png');
    ArtworkProvider.get('assets/new.png');
    final retained = ArtworkProvider.get('assets/recent.png');

    expect(identical(recent, touched), isTrue);
    expect(identical(touched, retained), isTrue);
  });

  test(
    'does not retain large inline data URI providers in the global cache',
    () {
      const artwork = 'data:image/png;base64,AA==';

      final first = ArtworkProvider.get(artwork);
      final second = ArtworkProvider.get(artwork);

      expect(identical(first, second), isFalse);
    },
  );
}
