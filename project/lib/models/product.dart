import 'package:cloud_firestore/cloud_firestore.dart';
//color wa7d fy al product
class ColorEntry {
  final String name;
  final String hex;
  final String imageUrl;

  const ColorEntry({
    required this.name,
    this.hex = '#000000',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'hex': hex,
        'imageUrl': imageUrl,
      };

  factory ColorEntry.fromMap(Map<String, dynamic> m) => ColorEntry(
        name: m['name'] ?? '',
        hex: m['hex'] ?? '#000000',
        imageUrl: m['imageUrl'] ?? '',
      );
}

class Product {
  final String id;
  final String name;
  final String category;
  final String gender;
  final double price;
  final String description;
  final String imagePath;
  final List<String> sizes;
  final Map<String, Map<String, int>> colorSizeQuantities;
  final List<String> colors;
  final List<ColorEntry> colorEntries;
  final bool isNew;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.gender = 'Men & Women',
    required this.price,
    required this.description,
    required this.imagePath,
    required this.sizes,
    this.colorSizeQuantities = const {},
    required this.colors,
    this.colorEntries = const [],
    this.isNew = false,
    this.isFeatured = false,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    //bgeb al color entries mn database
    final d = doc.data() as Map<String, dynamic>;
    final ceRaw = d['colorEntries'] as List? ?? [];
    final colorEntries = ceRaw
        .map((e) => ColorEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    //color ly size wy quant
    final csqRaw = d['colorSizeQuantities'] as Map?;
    final colorSizeQty = csqRaw != null
        ? csqRaw.map((color, sizes) => MapEntry(
              color.toString(),
              (sizes as Map).map((s, q) =>
                  MapEntry(s.toString(), (q as num).toInt())),
            ))
        : <String, Map<String, int>>{};

    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      gender: d['gender'] ?? 'Men & Women',
      price: (d['price'] as num).toDouble(),
      description: d['description'] ?? '',
      imagePath: d['imagePath'] ?? '',
      sizes: List<String>.from(d['sizes'] ?? ['S', 'M', 'L', 'XL']),
      colorSizeQuantities: colorSizeQty,
      colors: List<String>.from(d['colors'] ?? ['Black']),
      colorEntries: colorEntries,
      isNew: d['isNew'] ?? false,
      isFeatured: d['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'gender': gender,
        'price': price,
        'description': description,
        'imagePath': imagePath,
        'sizes': sizes,
        'colorSizeQuantities': colorSizeQuantities,
        'colors': colors,
        'colorEntries': colorEntries.map((c) => c.toMap()).toList(),
        'isNew': isNew,
        'isFeatured': isFeatured,
      };

  bool get isNetworkImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  bool get isOutOfStock =>
      colorSizeQuantities.isNotEmpty &&
      colorSizeQuantities.values
          .every((sizes) => sizes.values.every((q) => q <= 0));

  Map<String, int> stockForColor(String color) =>
      colorSizeQuantities[color] ?? {};
}