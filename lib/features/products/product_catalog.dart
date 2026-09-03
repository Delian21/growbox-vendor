import 'package:flutter/material.dart';
import '../../data/mock/mock_images.dart';

/// Display-ready product used by the products list and the product detail
/// screen. Kept in a single shared catalog so the list and `/products/:id`
/// page always show the same product.
class ProductItem {
  final String id, name, category, price, unit, description;
  final int stock;
  final IconData icon;
  final List<Color> gradientColors;
  final String? imageUrl;

  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    required this.icon,
    this.description = '',
    this.gradientColors = const [],
    this.imageUrl,
  });

  bool get isLowStock => stock <= 10;
}

/// The app's in-memory product catalog (single source of truth for the demo).
///
/// A [ChangeNotifier] so screens that show products (list, detail) stay in
/// sync when a product is added, edited or deleted from anywhere.
class ProductCatalog extends ChangeNotifier {
  ProductCatalog._() {
    _items.addAll(_build());
  }

  static final ProductCatalog instance = ProductCatalog._();

  final List<ProductItem> _items = [];

  List<ProductItem> get items => List.unmodifiable(_items);

  ProductItem? findById(String id) {
    for (final product in _items) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductItem addProduct(ProductItem product) {
    final id = (product.id.isEmpty || findById(product.id) != null)
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : product.id;
    final item = ProductItem(
      id: id,
      name: product.name,
      category: product.category,
      price: product.price,
      unit: product.unit,
      stock: product.stock,
      icon: product.icon,
      description: product.description,
      gradientColors: product.gradientColors,
      imageUrl: product.imageUrl,
    );
    _items.insert(0, item);
    notifyListeners();
    return item;
  }

  void updateProduct(ProductItem updated) {
    final index = _items.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _items[index] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    final lengthBefore = _items.length;
    _items.removeWhere((p) => p.id == id);
    if (_items.length != lengthBefore) {
      notifyListeners();
    }
  }

  static List<ProductItem> _build() {
    return [
      const ProductItem(id: 'p1', name: 'Fresh Tomatoes', category: 'Vegetables', price: '2,500', unit: 'kg', stock: 120, icon: Icons.circle, description: 'Fresh farm-grown tomatoes', gradientColors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)], imageUrl: ''),
      const ProductItem(id: 'p2', name: 'Sweet Potatoes', category: 'Tuber & Roots', price: '1,800', unit: 'kg', stock: 85, icon: Icons.egg_alt, description: 'Fresh sweet potatoes', gradientColors: [Color(0xFFFFB347), Color(0xFFFFA726)], imageUrl: ''),
      const ProductItem(id: 'p3', name: 'Bell Peppers', category: 'Vegetables', price: '3,200', unit: 'kg', stock: 45, icon: Icons.local_florist, description: 'Mixed colour bell peppers', gradientColors: [Color(0xFFFF8A65), Color(0xFFFF7043)], imageUrl: ''),
      const ProductItem(id: 'p4', name: 'Fresh Lettuce', category: 'Vegetables', price: '1,500', unit: 'bundle', stock: 8, icon: Icons.eco, description: 'Crisp lettuce heads', gradientColors: [Color(0xFF81C784), Color(0xFF66BB6A)], imageUrl: ''),
      const ProductItem(id: 'p5', name: 'Onions', category: 'Tuber & Roots', price: '1,200', unit: 'kg', stock: 200, icon: Icons.circle_outlined, description: 'Red and white onions', gradientColors: [Color(0xFFCE93D8), Color(0xFFBA68C8)], imageUrl: ''),
      const ProductItem(id: 'p6', name: 'Carrots', category: 'Vegetables', price: '1,800', unit: 'kg', stock: 95, icon: Icons.linear_scale, description: 'Fresh carrots', gradientColors: [Color(0xFFFFB74D), Color(0xFFFFA726)], imageUrl: ''),
      const ProductItem(id: 'p7', name: 'Fresh Oranges', category: 'Fruits', price: '2,000', unit: 'kg', stock: 150, icon: Icons.circle, description: 'Sweet navel oranges', gradientColors: [Color(0xFFFFB347), Color(0xFFFF9800)], imageUrl: ''),
      const ProductItem(id: 'p8', name: 'Watermelon', category: 'Fruits', price: '3,000', unit: 'piece', stock: 30, icon: Icons.water_drop, description: 'Seedless watermelon', gradientColors: [Color(0xFFEF5350), Color(0xFFE53935)], imageUrl: ''),
      const ProductItem(id: 'p9', name: 'Brown Rice', category: 'Grains & Cereals', price: '850', unit: 'kg', stock: 500, icon: Icons.grain, description: 'Whole grain brown rice', gradientColors: [Color(0xFFBCAAA4), Color(0xFFA1887F)], imageUrl: ''),
      const ProductItem(id: 'p10', name: 'Fresh Basil', category: 'Herbs & Spices', price: '500', unit: 'bunch', stock: 5, icon: Icons.spa, description: 'Aromatic fresh basil', gradientColors: [Color(0xFF66BB6A), Color(0xFF4CAF50)], imageUrl: ''),
      const ProductItem(id: 'p11', name: 'Palm Oil', category: 'Oils', price: '4,500', unit: 'litre', stock: 60, icon: Icons.opacity, description: 'Unrefined red palm oil, freshly pressed from mature palm fruits', gradientColors: [Color(0xFFFFB300), Color(0xFFFF8F00)], imageUrl: ''),
      const ProductItem(id: 'p12', name: 'Groundnut Oil', category: 'Oils', price: '5,500', unit: 'litre', stock: 40, icon: Icons.opacity, description: 'Cold-pressed groundnut oil with a rich, nutty flavour — perfect for frying', gradientColors: [Color(0xFFF9C74F), Color(0xFFE9A13B)], imageUrl: ''),
    ].map((p) {
      // Attach the bundled stock photo at runtime (const map lookups are not
      // allowed in const expressions).
      return ProductItem(
        id: p.id,
        name: p.name,
        category: p.category,
        price: p.price,
        unit: p.unit,
        stock: p.stock,
        icon: p.icon,
        description: p.description,
        gradientColors: p.gradientColors,
        imageUrl: MockImages.forProduct(p.name),
      );
    }).toList();
  }
}
