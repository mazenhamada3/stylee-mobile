import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService().getProducts(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading products', style: GoogleFonts.montserrat()));
          }
          final allProducts = snap.data ?? [];
          final featured = allProducts.where((p) => p.isFeatured).toList();
          final newArrivals = allProducts.where((p) => p.isNew).toList();
          final categories = allProducts
          .map((p) => p.category)
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
         ..sort();
          return CustomScrollView(
            slivers: [
              // ── Hero banner ──
              SliverToBoxAdapter(
                child: Image.asset(
                  'assets/images/products/New Collection image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: AppTheme.black,
                    child: Center(
                      child: Text('NEW COLLECTION',
                        style: GoogleFonts.montserrat(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (categories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: const AppSectionTitle('Categories'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final category = categories[i];
                        return GestureDetector(
                          onTap: () => context.go('/search?category=$category'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              // ── Featured ──
              if (featured.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppSectionTitle('Featured'),
                        TextButton(
                          onPressed: () => context.go('/search'),
                          child: Text('See All', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 252,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ProductCard(product: featured[i], width: 160),
                    ),
                  ),
                ),
              ],

              // ── New Arrivals ──
              if (newArrivals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                    child: const AppSectionTitle('New Arrivals'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: newArrivals[i]),
                      childCount: newArrivals.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
              ],

              // ── All Products (if no featured/new yet) ──
              if (featured.isEmpty && newArrivals.isEmpty && allProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: const AppSectionTitle('Products'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: allProducts[i]),
                      childCount: allProducts.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
