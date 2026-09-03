import 'package:flutter/material.dart';
import '../../features/products/product_catalog.dart';

/// App-facing products store.
///
/// Registered app-wide as a [ChangeNotifierProvider] (see main.dart). It is
/// backed by the shared [ProductCatalog] singleton — the single source of
/// truth for product data — so the list screen, the detail screen and any
/// future backend integration all read and write the same products, and
/// add / edit / delete operations stay in sync everywhere.
///
/// The provider forwards catalog notifications to its own listeners so
/// widgets can simply `watch<ProductsProvider>()`.
class ProductsProvider extends ChangeNotifier {
  ProductsProvider() {
    ProductCatalog.instance.addListener(_onCatalogChanged);
  }

  @override
  void dispose() {
    ProductCatalog.instance.removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() => notifyListeners();

  List<ProductItem> get products => ProductCatalog.instance.items;

  ProductItem? getProductById(String id) => ProductCatalog.instance.findById(id);

  ProductItem addProduct(ProductItem product) =>
      ProductCatalog.instance.addProduct(product);

  void updateProduct(ProductItem updated) =>
      ProductCatalog.instance.updateProduct(updated);

  void deleteProduct(String id) =>
      ProductCatalog.instance.deleteProduct(id);
}
