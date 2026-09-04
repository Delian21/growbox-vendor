/// Offline-first produce imagery bundled as Flutter assets.
///
/// Photos are sourced from Pexels (free to use — no attribution required) and
/// bundled under `assets/images/produce/` so the demo renders fully offline
/// with no network requests. When a real backend supplies product photos,
/// swap these asset paths for the returned image URLs.
///
/// Screens should still render these behind gradient/icon fallbacks so the UI
/// stays intact if an asset is ever missing.
class MockImages {
  MockImages._();

  static const String _assetsRoot = 'assets/images/produce/';

  static String produce(String file) => '$_assetsRoot$file';

  /// Product photos keyed by the product names used across the mock datasets
  /// (products catalog, orders, sales).
  static final Map<String, String> products = {
    'Fresh Tomatoes': produce('tomatoes.jpg'),
    'Sweet Potatoes': produce('sweet_potatoes.jpg'),
    'Bell Peppers': produce('bell_peppers.jpg'),
    'Green Peppers': produce('green_peppers.jpg'),
    'Fresh Lettuce': produce('lettuce.jpg'),
    'Organic Lettuce': produce('lettuce.jpg'),
    'Onions': produce('onions.jpg'),
    'Carrots': produce('carrots.jpg'),
    'Fresh Oranges': produce('oranges.jpg'),
    'Watermelon': produce('watermelon.jpg'),
    'Brown Rice': produce('brown_rice.jpg'),
    'Fresh Basil': produce('basil.jpg'),
    'Organic Maize': produce('maize.jpg'),
    'Yam': produce('yam.jpg'),
    'Eggs': produce('eggs.jpg'),
    'Cassava Flour': produce('cassava_flour.jpg'),
    'Palm Oil': produce('palm_oil.jpg'),
    'Groundnut Oil': produce('oils.jpg'),
  };

  static String? forProduct(String name) => products[name];

  /// Category photos used by the dashboard "Sales by Category" legend.
  static final Map<String, String> categories = {
    'Vegetables': produce('tomatoes.jpg'),
    'Fruits': produce('oranges.jpg'),
    'Grains & Cereals': produce('brown_rice.jpg'),
    'Legumes & Pulses': produce('legumes.jpg'),
    'Tuber & Roots': produce('sweet_potatoes.jpg'),
    'Fresh Proteins': produce('eggs.jpg'),
    'Oils': produce('oils.jpg'),
  };

  static String? forCategory(String name) => categories[name];

  /// Store profile imagery.
  static String get storeBanner => produce('store_banner.jpg');
  static String get storeLogo => produce('store_logo.jpg');
}
