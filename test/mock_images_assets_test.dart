import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:growbox_vendor/data/mock/mock_images.dart';

void main() {
  group('MockImages asset paths', () {
    test('every product photo resolves to a real bundled file', () {
      final assetPaths = <String>[
        ...MockImages.products.values,
        MockImages.storeBanner,
        MockImages.storeLogo,
      ];

      expect(assetPaths, isNotEmpty);

      for (final path in assetPaths) {
        expect(
          path,
          startsWith('assets/images/produce/'),
          reason: 'MockImages should only reference bundled produce assets, '
              'got: $path',
        );
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing bundled image referenced by MockImages: $path. '
              'Download the photo into assets/images/produce/ or fix the path.',
        );
      }
    });

    test('product names used across mock messages all have a photo', () {
      // Product names that appear in notification messages, order items and
      // the sales history. Keeping this list here guards against future mock
      // messages silently rendering without a photo.
      const referencedProductNames = [
        'Fresh Tomatoes',
        'Sweet Potatoes',
        'Bell Peppers',
        'Green Peppers',
        'Fresh Lettuce',
        'Organic Lettuce',
        'Onions',
        'Carrots',
        'Fresh Oranges',
        'Watermelon',
        'Brown Rice',
        'Fresh Basil',
        'Organic Maize',
        'Yam',
        'Eggs',
        'Cassava Flour',
        'Palm Oil',
        'Groundnut Oil',
      ];

      for (final name in referencedProductNames) {
        final path = MockImages.forProduct(name);
        expect(
          path,
          isNotNull,
          reason: 'No photo registered in MockImages for product "$name"',
        );
        expect(
          File(path!).existsSync(),
          isTrue,
          reason: 'Missing bundled image for product "$name": $path',
        );
      }
    });
  });
}
