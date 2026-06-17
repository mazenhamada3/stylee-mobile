import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    // A wider image ratio prevents bottom-overflow in grid and
                    // horizontal product cards on smaller screens.
                    aspectRatio: 1.0,
                    child: _ProductImage(product: product),
                  ),
                  if (product.isNew)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('NEW',
                            style: GoogleFonts.montserrat(
                              color: AppTheme.white, fontSize: 9,
                              fontWeight: FontWeight.w700, letterSpacing: 1,
                            )),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category,
                      style: GoogleFonts.montserrat(
                        fontSize: 9, color: AppTheme.grey,
                        fontWeight: FontWeight.w500, letterSpacing: 0.5,
                      )),
                  const SizedBox(height: 2),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppTheme.black,
                      )),
                  const SizedBox(height: 3),
                  if (product.isOutOfStock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('OUT OF STOCK',style: GoogleFonts.montserrat(fontSize: 9,fontWeight: FontWeight.w700,color: Colors.red)),
                    ),
                  Text('\$${product.price.toInt()}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppTheme.black,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Handles both asset paths and network URLs gracefully.
class _ProductImage extends StatelessWidget {
  final Product product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.isNetworkImage) {
      return Image.network(
        product.imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: const Color(0xFFE8E8E8),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.grey,
                  ),
                ),
              ),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      product.imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE0E0E0),
        child: const Center(
          child: Icon(Icons.image_not_supported,
              color: Colors.grey, size: 32),
        ),
      );
}
