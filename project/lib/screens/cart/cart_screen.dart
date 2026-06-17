import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoCtrl = TextEditingController();
  final _firestoreService = FirestoreService();

 
  @override
  void dispose() {
    _promoCtrl.dispose(); 
    _removeDeletedProducts();
    super.dispose();
  }

  void _removeDeletedProducts() {
    _firestoreService.getProducts().listen((currentProducts) {

      final cart = context.read<CartProvider>();
      final existingIds = currentProducts.map((p) => p.id).toSet();

      for (final item in List.from(cart.items)) {
        if (!existingIds.contains(item.productId)) {
          cart.removeItem(item);
        }
      }
    });
  }

  void _applyPromo(CartProvider cart) {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a promo code first')),
      );
      return;
    }
    final isValid = cart.applyPromo(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isValid ? 'Promo code applied' : 'Invalid promo code',
        ),
        backgroundColor: isValid ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: AppTheme.black,
      ),

      body: cart.items.isEmpty
          ? _EmptyCart(onShopNow: () => context.go('/home'))
          : _buildCartList(cart),
    );
  }

  Widget _buildCartList(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cart.items.map((item) => _buildCartItemTile(cart, item)),

        const SizedBox(height: 16),
        AppTextField(
          controller: _promoCtrl,
          hint: 'Enter promo code',
          capitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),

        AppButton(
          onPressed: () => _applyPromo(cart),
          text: 'Apply',
        ),
        const SizedBox(height: 20),

        _CartSummary(cart: cart),
        const SizedBox(height: 20),

        AppButton(
          onPressed: cart.items.isEmpty
              ? null                            // disabled if cart empty
              : () => context.push('/checkout'),
          text: 'Checkout',
        ),

      ],
    );
  }

  // ── Builds ONE cart item tile with live stock checking ──
  Widget _buildCartItemTile(CartProvider cart, item) {

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        int maxQty = 999;

        if (snapshot.hasData) {
          final products = snapshot.data!;
          final matchedProduct = products
              .where((p) => p.id == item.productId)
              .firstOrNull;

          if (matchedProduct != null) {
            final stock = matchedProduct.stockForColor(item.color);
            maxQty = stock[item.size] ?? 0;

          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cart.removeItem(item);
            });
          }
        }
        return CartItemTile(
          item: item,
          onIncrease: item.quantity >= maxQty
              ? null
              : () => cart.updateQty(item, item.quantity + 1),

          onDecrease: () => cart.updateQty(item, item.quantity - 1),

          onRemove: () => cart.removeItem(item),
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShopNow;
  const _EmptyCart({required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [

            const Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: AppTheme.grey,
            ),
            const SizedBox(height: 16),

            Text(
              'Your cart is empty',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Add products first, then come back to checkout.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 24),

            AppButton(onPressed: onShopNow, text: 'Shop Now'),

          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Items',    value: '${cart.itemCount}'),
          const SizedBox(height: 8),

          _SummaryRow(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),


          _SummaryRow(label: 'Shipping', value: '\$${cart.shipping.toStringAsFixed(2)}'),

   
          if (cart.promoDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Promo ${cart.appliedPromo ?? ''}',
              value: '-\$${cart.promoDiscount.toStringAsFixed(2)}',
              valueColor: Colors.green,  // green = saving money
            ),
          ],

          // Divider line between rows and total
          const Divider(height: 24),

          _SummaryRow(
            label: 'Total',
            value: '\$${cart.total.toStringAsFixed(2)}',
            isBold: true,
          ),

        ],
      ),
    );
  }
}


class _SummaryRow extends StatelessWidget {
  final String label;       // text on the left  e.g. "Subtotal"
  final String value;       // text on the right e.g. "$29.99"
  final bool isBold;        // true only for the Total row
  final Color? valueColor;  // optional — green for discount row

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,   // default: regular weight
    this.valueColor,       // default: black
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize:   isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color:      isBold ? AppTheme.black : AppTheme.grey,
          ),
        ),

        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize:   isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color:      valueColor ?? AppTheme.black,
          ),
        ),

      ],
    );
  }
}