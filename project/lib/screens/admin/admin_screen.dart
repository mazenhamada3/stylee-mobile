import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.grey,
          labelStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'PRODUCTS'),
            Tab(text: 'ORDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductsTab(service: _service),
          _OrdersTab(service: _service),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Products Tab
// ─────────────────────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  final FirestoreService service;
  const _ProductsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Add Product button ──
        AppButton(
          text: '+ Add New Product',
          onPressed: () => _showProductForm(context, null),
        ),
        const SizedBox(height: 20),
        Text('All Products', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        StreamBuilder<List<Product>>(
          stream: service.getProducts(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final products = snap.data!;
            if (products.isEmpty) {
              return Center(child: Text('No products yet', style: GoogleFonts.montserrat(color: AppTheme.grey)));
            }
            return Column(
              children: products.map((p) => _ProductAdminTile(product: p, service: service)).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showProductForm(BuildContext context, Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductFormSheet(product: product, service: service),
    );
  }
}

class _ProductAdminTile extends StatelessWidget {
  final Product product;
  final FirestoreService service;
  const _ProductAdminTile({required this.product, required this.service});

  @override
  Widget build(BuildContext context) {
    final isNetwork = product.imagePath.startsWith('http');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 52, height: 52,
            child: isNetwork
                ? Image.network(product.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey))
                : Image.asset(product.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey)),
          ),
        ),
        title: Text(product.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text('\$${product.price}  •  ${product.category}', style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.background,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => _ProductFormSheet(product: product, service: service),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text('Delete "${product.name}"? This cannot be undone.', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteProduct(product.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Form Sheet (Add / Edit)
// ─────────────────────────────────────────────────────────────────────────────
class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final FirestoreService service;
  const _ProductFormSheet({required this.product, required this.service});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  // Colors with sizes + quantities per color
  // Structure: { colorName: { hex: '#RRGGBB', sizes: { 'S': qty, 'M': qty, ... } } }
  List<_ColorEntry> _colorEntries = [];

  bool _isNew = false;
  bool _isFeatured = false;
  bool _saving = false;

  static const _availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _fixedCategories = [
  'JACKETS',
  'SETS',
  'OUTERWEAR',
  'SHIRTS',
  'HOODIES',
  'PANTS',
  'SHOES',
  'ACCESSORIES',
  'BAGS',
  'OTHER',
];

String _selectedCategory = 'JACKETS';
static const _genderOptions = ['Men', 'Women', 'Men & Women'];
String _selectedGender = 'Men & Women';
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.price.toString();
      _descCtrl.text = p.description;
      _imageUrlCtrl.text = p.imagePath;
      _categoryCtrl.text = p.category;
      if (_fixedCategories.contains(p.category)) {
        _selectedCategory = p.category;
      } else {
        _selectedCategory = 'OTHER';
      }
            _isNew = p.isNew;
      _isFeatured = p.isFeatured;
      if (_genderOptions.contains(p.gender)) {
        _selectedGender = p.gender;
      }
      // Build color entries from existing data
      for (final ce in p.colorEntries) {
        final entry = _ColorEntry(name: ce.name, hex: ce.hex, imageUrl: ce.imageUrl);
        // Load per-color stock — fall back to aggregate only if no per-color data
        final perColorQty = p.colorSizeQuantities[ce.name];
        for (final s in _availableSizes) {
          entry.sizeQty[s] = perColorQty?[s] ?? 0;
        }
        _colorEntries.add(entry);
      }
      // If no colorEntries, build from colors list
      if (_colorEntries.isEmpty) {
        for (final c in p.colors) {
          final entry = _ColorEntry(name: c, hex: '#000000', imageUrl: '');
          final perColorQty = p.colorSizeQuantities[c];
          for (final s in _availableSizes) {
            entry.sizeQty[s] = perColorQty?[s] ?? 0;
          }
          _colorEntries.add(entry);
        }
      }
    } else {
      // Default: one empty color entry
      _colorEntries.add(_ColorEntry(name: '', hex: '#000000', imageUrl: ''));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose();
    _imageUrlCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();
    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and price are required')));
      return;
    }
    final price = double.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')));
      return;
    }
    final category = _selectedCategory == 'OTHER'
        ? _categoryCtrl.text.trim().toUpperCase()
        : _selectedCategory;

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a category')),
      );
      return;
    }
    setState(() => _saving = true);

    // Build per-color stock map and aggregate totals
    final colorSizeQty = <String, Map<String, int>>{};
    final allSizes = <String>{};
    final aggregatedQty = <String, int>{};
    for (final ce in _colorEntries) {
      if (ce.name.isEmpty) continue;
      final perColor = <String, int>{};
      for (final entry in ce.sizeQty.entries) {
        perColor[entry.key] = entry.value;
        if (entry.value > 0) allSizes.add(entry.key);
        aggregatedQty[entry.key] = (aggregatedQty[entry.key] ?? 0) + entry.value;
      }
      colorSizeQty[ce.name] = perColor;
    }

    final data = {
      'name': name,
      'price': price,
      'description': _descCtrl.text.trim(),
      'imagePath': _imageUrlCtrl.text.trim().isNotEmpty
          ? _imageUrlCtrl.text.trim()
          : (widget.product?.imagePath ?? 'assets/images/products/Premium Puffer.png'),
      'category': category,
      'gender': _selectedGender,
      'colors': _colorEntries.where((c) => c.name.isNotEmpty).map((c) => c.name).toList(),
      'colorEntries': _colorEntries
          .where((c) => c.name.isNotEmpty)
          .map((c) => {
                'name': c.name,
                'hex': c.hex,
                'imageUrl': c.imageUrl,
              })
          .toList(),
      'sizes': _availableSizes.where((s) => allSizes.contains(s)).toList(),
      'sizeQuantities': aggregatedQty,
      'colorSizeQuantities': colorSizeQty,
      'isNew': _isNew,
      'isFeatured': _isFeatured,
    };

    try {
      if (widget.product != null) {
        await widget.service.updateProduct(widget.product!.id, data);
      } else {
        await widget.service.addProduct(data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product != null ? 'Product updated!' : 'Product added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.product != null ? 'Edit Product' : 'Add Product',
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Basic info
            AppTextField(controller: _nameCtrl, hint: 'Product Name', capitalization: TextCapitalization.words),
            const SizedBox(height: 10),
            AppTextField(controller: _priceCtrl, hint: 'Price (e.g. 99.99)', type: TextInputType.number),
            const SizedBox(height: 10),

            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _fixedCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                    if (value != 'OTHER') {
                      _categoryCtrl.text = value;
                    } else {
                      _categoryCtrl.clear();
                    }
                  });
                },
              ),
            ),
          ),

          if (_selectedCategory == 'OTHER') ...[
            const SizedBox(height: 10),
            AppTextField(
              controller: _categoryCtrl,
              hint: 'Enter new category',
              capitalization: TextCapitalization.characters,
            ),
          ],
            const SizedBox(height: 10),
            // ── Gender Dropdown ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  isExpanded: true,
                  items: _genderOptions.map((g) {
                    return DropdownMenuItem<String>(
                      value: g,
                      child: Text(g, style: GoogleFonts.montserrat(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedGender = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppTextField(controller: _descCtrl, hint: 'Description'),
            const SizedBox(height: 10),
            AppTextField(controller: _imageUrlCtrl, hint: 'Image URL (https://...) or leave blank for default'),

            // Toggles
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('New Arrival', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _isNew,
                  onChanged: (v) => setState(() => _isNew = v),
                  activeColor: AppTheme.black,
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Featured', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v),
                  activeColor: AppTheme.black,
                ),
              ),
            ]),

            // Colors section
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Colors & Stock', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Color', style: GoogleFonts.montserrat(fontSize: 12)),
                  onPressed: () => setState(() => _colorEntries.add(_ColorEntry(name: '', hex: '#000000', imageUrl: ''))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._colorEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final ce = entry.value;
              return _ColorEntryCard(
                colorEntry: ce,
                availableSizes: _availableSizes,
                onDelete: () => setState(() => _colorEntries.removeAt(idx)),
                onChanged: () => setState(() {}),
              );
            }),

            const SizedBox(height: 20),
            AppButton(loading: _saving, text: widget.product != null ? 'Update Product' : 'Add Product', onPressed: _save),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ColorEntry {
  String name;
  String hex;
  String imageUrl;
  Map<String, int> sizeQty = {};

  _ColorEntry({required this.name, required this.hex, required this.imageUrl});
}

class _ColorEntryCard extends StatefulWidget {
  final _ColorEntry colorEntry;
  final List<String> availableSizes;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _ColorEntryCard({required this.colorEntry, required this.availableSizes, required this.onDelete, required this.onChanged});

  @override
  State<_ColorEntryCard> createState() => _ColorEntryCardState();
}

class _ColorEntryCardState extends State<_ColorEntryCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hexCtrl;
  late final TextEditingController _imgCtrl;
  late final Map<String, TextEditingController> _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.colorEntry.name);
    _hexCtrl = TextEditingController(text: widget.colorEntry.hex);
    _imgCtrl = TextEditingController(text: widget.colorEntry.imageUrl);
    _qtyCtrl = {
      for (final s in widget.availableSizes)
        s: TextEditingController(text: (widget.colorEntry.sizeQty[s] ?? 0).toString())
    };
    for (final s in widget.availableSizes) {
      _qtyCtrl[s]!.addListener(() {
        widget.colorEntry.sizeQty[s] = int.tryParse(_qtyCtrl[s]!.text) ?? 0;
        widget.onChanged();
      });
    }
    _nameCtrl.addListener(() { widget.colorEntry.name = _nameCtrl.text; widget.onChanged(); });
    _hexCtrl.addListener(() { widget.colorEntry.hex = _hexCtrl.text; widget.onChanged(); });
    _imgCtrl.addListener(() { widget.colorEntry.imageUrl = _imgCtrl.text; widget.onChanged(); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _hexCtrl.dispose(); _imgCtrl.dispose();
    for (final c in _qtyCtrl.values) c.dispose();
    super.dispose();
  }

  Color _previewColor() {
    try {
      final hex = widget.colorEntry.hex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Color preview circle
              GestureDetector(
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _previewColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Color name (e.g. Black)',
                    hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.grey),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: widget.onDelete),
            ],
          ),
          const SizedBox(height: 8),
          // Hex input
          Row(children: [
            Text('Hex: ', style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey)),
            Expanded(
              child: TextField(
                controller: _hexCtrl,
                style: GoogleFonts.montserrat(fontSize: 12),
                decoration: InputDecoration(
                  hintText: '#000000',
                  hintStyle: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
          // Image URL
          Row(children: [
            Text('Img: ', style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey)),
            Expanded(
              child: TextField(
                controller: _imgCtrl,
                style: GoogleFonts.montserrat(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'https://... (optional)',
                  hintStyle: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
          const Divider(height: 16),
          // Size quantities
          Text('Stock per size:', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableSizes.map((s) => SizedBox(
              width: 70,
              child: Column(
                children: [
                  Text(s, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _qtyCtrl[s],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orders Tab (Admin)
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final FirestoreService service;
  const _OrdersTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getAllOrders(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) {
          return Center(
            child: Text('No orders yet', style: GoogleFonts.montserrat(color: AppTheme.grey)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _AdminOrderCard(order: orders[i], service: service),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final FirestoreService service;
  const _AdminOrderCard({required this.order, required this.service});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'Processing';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = (order['items'] as List?) ?? [];
    final address = order['address'] ?? 'N/A';
    final orderId = order['id'] as String;
    final shortId = orderId.substring(0, 6).toUpperCase();

    final statusColor = status == 'Delivered'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.orange;

    return Card(
      color: AppTheme.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #$shortId', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('\$${total.toStringAsFixed(2)}  •  ${items.length} item(s)',
              style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey)),
            const SizedBox(height: 4),
            Text('Ship to: $address',
              style: GoogleFonts.montserrat(fontSize: 12, color: AppTheme.grey),
              maxLines: 2, overflow: TextOverflow.ellipsis),

            // Items list
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...items.take(3).map((item) {
                final m = item as Map;
                return Text('• ${m['name']} — ${m['size']} / ${m['color']} × ${m['quantity']}',
                  style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.black));
              }),
              if (items.length > 3)
                Text('+ ${items.length - 3} more...', style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey)),
            ],

            // Action buttons
            if (status != 'Delivered' && status != 'Cancelled') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text('Mark Delivered', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await service.updateOrderStatus(orderId, 'Delivered');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order marked as delivered'), backgroundColor: Colors.green));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text('Cancel Order', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _confirmCancel(context, orderId),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel Order', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text('Cancel this order?', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.updateOrderStatus(orderId, 'Cancelled');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}