import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;

  const SearchScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  String _selectedGender = 'All';

  static const _genders = ['All', 'Men', 'Women', 'Men & Women'];

  @override
  void initState() {
    super.initState();

    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> all) {
    return all.where((p) {
      final q = _query.toLowerCase();

      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);

      final matchesCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;

      final matchesGender =
          _selectedGender == 'All' || p.gender == _selectedGender;

      return matchesQuery && matchesCat && matchesGender;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Text(
          'Search',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: false,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search products, categories…',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.grey,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppTheme.grey,
                          ),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService().getProducts(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snap.data!;

          final categories = [
            'All',
            ...products
                .map((p) => p.category)
                .where((c) => c.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }

          final results = _filter(products);

          return Column(
            children: [
              Container(
                color: AppTheme.white,
                child: Column(
                  children: [
                    _ChipRow(
                      label: 'Category',
                      values: categories,
                      selected: _selectedCategory,
                      onSelect: (v) => setState(() => _selectedCategory = v),
                    ),
                    _ChipRow(
                      label: 'Gender',
                      values: _genders,
                      selected: _selectedGender,
                      onSelect: (v) => setState(() => _selectedGender = v),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 56,
                              color: AppTheme.lightGrey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No products in the store yet',
                              style: GoogleFonts.montserrat(
                                color: AppTheme.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 56,
                                  color: AppTheme.lightGrey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No results for "$_query"',
                                  style: GoogleFonts.montserrat(
                                    color: AppTheme.grey,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _ctrl.clear();
                                    setState(() {
                                      _query = '';
                                      _selectedCategory = 'All';
                                      _selectedGender = 'All';
                                    });
                                  },
                                  child: Text(
                                    'Clear filters',
                                    style: GoogleFonts.montserrat(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Text(
                                  '${results.length} product${results.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: AppTheme.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: results.length,
                                  itemBuilder: (_, i) =>
                                      ProductCard(product: results[i]),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final void Function(String) onSelect;

  const _ChipRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: values.map((v) {
          final active = v == selected;
          return GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppTheme.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppTheme.black : AppTheme.lightGrey,
                ),
              ),
              child: Text(
                v,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.white : AppTheme.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}