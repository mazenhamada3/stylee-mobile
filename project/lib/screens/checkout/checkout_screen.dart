import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cardCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _service = FirestoreService();
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await _service.getUserProfile(uid);
    if (!mounted) return;
    final address = profile?['address']?.toString() ?? '';
    if (address.isNotEmpty && _addressCtrl.text.isEmpty) {
      _addressCtrl.text = address;
    }
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
  bool _validateCheckoutFields() {
  final card = _cardCtrl.text.trim().replaceAll(' ', '');
  final name = _nameCtrl.text.trim();
  final expiry = _expiryCtrl.text.trim();
  final cvv = _cvvCtrl.text.trim();
  final address = _addressCtrl.text.trim();

  if (card.length != 16 || int.tryParse(card) == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid 16-digit card number'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  if (name.isEmpty || name.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter the cardholder name'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
  if (!expiryRegex.hasMatch(expiry)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter expiry date in MM/YY format'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  if (cvv.length != 3 || int.tryParse(cvv) == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid 3-digit CVV'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  if (address.isEmpty || address.length < 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your full shipping address'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  return true;
}

  Future<void> _placeOrder(CartProvider cart) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final address = _addressCtrl.text.trim();

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      context.go('/login');
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      context.go('/cart');
      return;
    }
    if (!_validateCheckoutFields()) {
      return;
    }

    try {
      setState(() => _placingOrder = true);
      await _service.placeOrder(
        uid: uid,
        items: List.of(cart.items),
        total: cart.total,
        address: address,
      );
      await cart.clearCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: AppTheme.black),
      body: cart.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_checkout, size: 72, color: AppTheme.grey),
                    const SizedBox(height: 16),
                    Text('Nothing to checkout', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                    AppButton(onPressed: () => context.go('/home'), text: 'Shop Now'),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSectionTitle('Card Details'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _cardCtrl,
                  hint: 'Card Number - 16 digits',
                  type: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),const SizedBox(height: 12),
                AppTextField(controller: _nameCtrl, hint: 'Cardholder Name', capitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: _expiryCtrl, hint: 'MM/YY', type: TextInputType.datetime)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(
                  controller: _cvvCtrl,
                  hint: 'CVV - 3 digits',
                  type: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 20),
                const AppSectionTitle('Shipping Address'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressCtrl,
                  hint: 'Enter your shipping address',
                  capitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                const AppSectionTitle('Order Summary'),
                const SizedBox(height: 12),
                ...cart.items.map((i) => CartItemTile(item: i, showControls: false)),
                const SizedBox(height: 12),
                _CheckoutTotal(cart: cart),
                const SizedBox(height: 20),
                AppButton(
                  onPressed: _placingOrder ? null : () => _placeOrder(cart),
                  text: 'Submit Order',
                  loading: _placingOrder,
                ),
              ],
            ),
    );
  }
}

class _CheckoutTotal extends StatelessWidget {
  final CartProvider cart;
  const _CheckoutTotal({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _Row(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _Row(label: 'Shipping', value: '\$${cart.shipping.toStringAsFixed(2)}'),
          if (cart.promoDiscount > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'Promo', value: '-\$${cart.promoDiscount.toStringAsFixed(2)}', valueColor: Colors.green),
          ],
          const Divider(height: 24),
          _Row(label: 'Total', value: '\$${cart.total.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? AppTheme.black : AppTheme.grey)),
        Text(value, style: GoogleFonts.montserrat(fontSize: bold ? 16 : 13, fontWeight: FontWeight.w800, color: valueColor ?? AppTheme.black)),
      ],
    );
  }
}
