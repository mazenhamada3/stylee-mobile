import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {


  String? selectedSize;
  String? selectedColor;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    if (product.colors.isNotEmpty) {
      selectedColor = product.colors.first;
    }

    final stockMap = product.stockForColor(selectedColor ?? '');
    for (final size in product.sizes) {
      final qty = stockMap[size] ?? 1;
      if (qty > 0) {
        selectedSize = size;
        break;
      }
    }
  }

  void _onColorChanged(String newColor) {
    final stockMap = widget.product.stockForColor(newColor);
    String? newSize;
    for (final size in widget.product.sizes) {
      if ((stockMap[size] ?? 0) > 0) {
        newSize = size;
        break;
      }
    }
    setState(() {
      selectedColor = newColor;
      selectedSize = newSize;
    });
  }

  void _onSizeChanged(String newSize) {
    setState(() {
      selectedSize = newSize;
    });
  }

  bool get _cannotAddToCart {
    if (widget.product.isOutOfStock) return true;
    if (selectedSize == null) return true;

    final qty = widget.product
        .stockForColor(selectedColor ?? '')[selectedSize!] ?? 0;
    return qty <= 0;
  }

  void _addToCart() {
    context.read<CartProvider>().addItemFromProduct(
      widget.product,
      selectedSize!,
      selectedColor ?? '',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.product.name} added to cart!',
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: AppTheme.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImage() {
    final product = widget.product;

    String? colorImageUrl;
    if (selectedColor != null) {
      final colorEntry = product.colorEntries
          .where((e) => e.name == selectedColor)
          .firstOrNull;
      if (colorEntry != null && colorEntry.imageUrl.isNotEmpty) {
        colorImageUrl = colorEntry.imageUrl;
      }
    }

    final imagePath = colorImageUrl ?? product.imagePath;
    final isUrl = imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://');

    // Fallback if image fails to load
    Widget placeholder = Container(
      height: 340,
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
      ),
    );

    if (isUrl) {
      return Image.network(
        imagePath,
        height: 340,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      return Image.asset(
        imagePath,
        height: 340,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hexMap = {
      for (var entry in product.colorEntries) entry.name: entry.hex
    };
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      _buildImage(),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),

                      if (product.isNew)
                        Positioned(
                          top: 60,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          product.category,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: AppTheme.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${product.price.toInt()}',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          product.description,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: AppTheme.grey,
                            height: 1.6,
                          ),
                        ),

                        if (product.colors.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text('Color: ', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                              Text(selectedColor ?? '', style: GoogleFonts.montserrat(color: AppTheme.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ColorSelector(
                            colors: product.colors,
                            selected: selectedColor,
                            hexMap: hexMap,
                            onSelect: _onColorChanged,
                          ),
                        ],

                        if (product.sizes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Size', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),

                          SizeSelector(
                            sizes: product.sizes,
                            selected: selectedSize,
                            quantities: product.stockForColor(selectedColor ?? ''),
                            onSelect: _onSizeChanged,
                          ),
                        ],

                        if (product.isOutOfStock) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Out of Stock',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: AppButton(
              onPressed: _cannotAddToCart ? null : _addToCart,
              text: product.isOutOfStock ? 'Out of Stock' : 'Add to Cart',
            ),
          ),

        ],
      ),
    );
  }
}