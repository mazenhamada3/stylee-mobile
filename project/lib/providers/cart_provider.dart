import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
 
class CartProvider extends ChangeNotifier {
  final _service = FirestoreService();

  List<CartItem> _items = [];
  StreamSubscription? _sub;
  double _promoDiscount = 0;
  String? _appliedPromo;
  String? _listenedUid;

  List<CartItem> get items        => _items;
  int    get itemCount            => _items.fold(0, (s, i) => s + i.quantity);
  double get subtotal             => _items.fold(0.0, (s, i) => s + i.total);
  double get shipping             => _items.isEmpty ? 0.0 : 12.0;
  double get promoDiscount        => _promoDiscount;
  double get total                => subtotal + shipping - _promoDiscount;
  String? get appliedPromo        => _appliedPromo;

  CartProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startListening(user.uid);
      } else {
        stopListening();
      }
    });
  }

  void startListening(String uid) {
    if (_listenedUid == uid && _sub != null) return; // already listening
    //low fy sub 2dym mn user tany  4ylo
    _sub?.cancel();
    _listenedUid = uid;
    _sub = _service.getCart(uid).listen((items) {
      _items = items;
      _recalculatePromoIfNeeded();
      notifyListeners();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _listenedUid = null;
    _items = [];
    _promoDiscount = 0;
    _appliedPromo = null;
    notifyListeners();
  }

  void addItemFromProduct(Product product, String size, String color) {
    final item = CartItem(
      productId: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      imagePath: product.imagePath,
      size: size,
      color: color,
      quantity: 1,
    );
    addItem(item);
  }

  Future<void> addItem(CartItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.addToCart(uid, item);
  }

  Future<void> updateQty(CartItem item, int qty) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (qty <= 0) {
      await _service.removeFromCart(uid, item);
    } else {
      await _service.updateCartQty(uid, item, qty);
    }
  }

  Future<void> removeItem(CartItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.removeFromCart(uid, item);
  }

  Future<void> clearCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.clearCart(uid);
    _promoDiscount = 0;
    _appliedPromo = null;
    notifyListeners();
  }

  bool applyPromo(String code) {
    if (code.toUpperCase() == 'STYLEE20') {
      _appliedPromo = code.toUpperCase();
      _recalculatePromoIfNeeded();
      notifyListeners();
      return true;
    }
    _appliedPromo = null;
    _promoDiscount = 0;
    notifyListeners();
    return false;
  }

  void _recalculatePromoIfNeeded() {
    if (_appliedPromo == 'STYLEE20') {
      _promoDiscount = subtotal * 0.20;
    } else {
      _promoDiscount = 0;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}