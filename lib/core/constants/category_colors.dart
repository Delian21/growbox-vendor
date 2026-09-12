import 'package:flutter/material.dart';

/// Canonical category colours shared by the dashboard "Sales by Category"
/// donut and the products screen filter chips, so a category always wears
/// the same hue across the app.
///
/// Hues echo the produce itself (vegetables green, fruits orange, grains
/// gold, proteins red, ...). All are mutually distinct — never map two
/// categories to the same colour.
class CategoryColors {
  CategoryColors._();

  static const Color vegetables = Color(0xFF22A064);
  static const Color fruits = Color(0xFFE07B39);
  static const Color grains = Color(0xFFEAB308);
  static const Color legumes = Color(0xFF8B5CF6);
  static const Color tubers = Color(0xFFB45309);
  static const Color oils = Color(0xFF0891B2);
  static const Color proteins = Color(0xFFDC2626);
  static const Color mushrooms = Color(0xFF8D6E63);
  static const Color herbs = Color(0xFF558B2F);
  static const Color nuts = Color(0xFF78350F);
  static const Color others = Color(0xFF94A3B8);

  static const Map<String, Color> byName = {
    'Vegetables': vegetables,
    'Fruits': fruits,
    'Grains & Cereals': grains,
    'Legumes & Pulses': legumes,
    'Tuber & Roots': tubers,
    'Oils': oils,
    'Fresh Proteins': proteins,
    'Mushrooms': mushrooms,
    'Herbs & Spices': herbs,
    'Nut & Seeds': nuts,
    'Others': others,
  };

  static Color? forCategory(String name) => byName[name];

  /// Label colour to place on top of a category colour. Bright hues (the
  /// gold) need dark text for contrast; the rest take white.
  static const Set<String> _brightHues = {'Grains & Cereals'};

  static Color labelOn(String category) =>
      _brightHues.contains(category) ? const Color(0xFF1A1A1A) : Colors.white;
}