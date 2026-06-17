import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─── Products ──────────────────────────────────────────────────────────────
  Stream<List<Product>> getProducts() => _db
      .collection('products')
      .snapshots()
      .map((s) => s.docs.map(Product.fromFirestore).toList());

  Future<void> addProduct(Map<String, dynamic> data) =>
      _db.collection('products').add(data);

  Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      _db.collection('products').doc(id).update(data);

  Future<void> deleteProduct(String id) =>
      _db.collection('products').doc(id).delete();

  Future<void> resetAndReseed() async {
    final snap = await _db.collection('products').get();
    for (final d in snap.docs) await d.reference.delete();
    await seedProducts(force: true);
  }

  // ─── Cart ───────────────────────────────────────────────────────────────────
  Stream<List<CartItem>> getCart(String uid) => _db
      .collection('users').doc(uid).collection('cart')
      .snapshots()
      .map((s) => s.docs.map((d) => CartItem.fromMap(d.data())).toList());

  Future<void> addToCart(String uid, CartItem item) async {
    final ref = _db.collection('users').doc(uid).collection('cart').doc(item.cartKey);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> updateCartQty(String uid, CartItem item, int qty) =>
      _db.collection('users').doc(uid).collection('cart').doc(item.cartKey)
          .update({'quantity': qty});

  Future<void> removeFromCart(String uid, CartItem item) =>
      _db.collection('users').doc(uid).collection('cart').doc(item.cartKey).delete();

  Future<void> clearCart(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('cart').get();
    for (final d in snap.docs) await d.reference.delete();
  }

  // ─── Orders (user) ──────────────────────────────────────────────────────────
  Future<void> placeOrder({
    required String uid,
    required List<CartItem> items,
    required double total,
    required String address,
  }) async {
    if (items.isEmpty) throw Exception('Cart is empty');

    final adminOrderRef = _db.collection('orders').doc();

    await _db.runTransaction((transaction) async {
      final Map<String, Map<String, Map<String, int>>> requestedByProduct = {};
      for (final item in items) {
        requestedByProduct.putIfAbsent(item.productId, () => {});
        requestedByProduct[item.productId]!.putIfAbsent(item.color, () => {});
        requestedByProduct[item.productId]![item.color]![item.size] =
            (requestedByProduct[item.productId]![item.color]![item.size] ?? 0) + item.quantity;
      }

      final productSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final productId in requestedByProduct.keys) {
        final ref = _db.collection('products').doc(productId);
        final snap = await transaction.get(ref);
        if (!snap.exists) throw Exception('A product in your cart is no longer available');
        productSnapshots[productId] = snap;
      }

      for (final productId in requestedByProduct.keys) {
        final snap = productSnapshots[productId]!;
        final data = snap.data() ?? {};

        final csqRaw = data['colorSizeQuantities'] as Map?;
        if (csqRaw == null || csqRaw.isEmpty) continue;

        final updatedCsq = csqRaw.map((color, sizes) => MapEntry(
              color.toString(),
              Map<String, dynamic>.from(sizes as Map),
            ));

        for (final colorEntry in requestedByProduct[productId]!.entries) {
          final color = colorEntry.key;
          for (final sizeEntry in colorEntry.value.entries) {
            final size = sizeEntry.key;
            final requested = sizeEntry.value;
            final itemName = items.firstWhere((i) => i.productId == productId).name;

            final colorMap = updatedCsq[color] as Map<String, dynamic>?;
            final available = ((colorMap?[size] as num?)?.toInt() ?? 0);
            if (available < requested) {
              throw Exception('$itemName ($color / $size) has only $available item(s) left');
            }
            (updatedCsq[color] as Map<String, dynamic>)[size] = available - requested;
          }
        }

        transaction.update(
          _db.collection('products').doc(productId),
          {'colorSizeQuantities': updatedCsq},
        );
      }

      final orderData = {
        'userId': uid,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': items.fold<double>(0.0, (sum, i) => sum + i.total),
        'total': total,
        'address': address,
        'status': 'Processing',
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(adminOrderRef, orderData);
    });
  }

  Stream<List<Map<String, dynamic>>> getOrders(String uid) => _db
    .collection('orders')
    .where('userId', isEqualTo: uid)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    
  // ─── Orders (admin) ─────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getAllOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> updateOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({'status': status});

  // ─── User Profile ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, {String? name, String? address}) =>
      _db.collection('users').doc(uid).set({
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ─── Seed Data ───────────────────────────────────────────────────────────────
  Future<void> seedProducts({bool force = false}) async {
    final col = _db.collection('products');
    if (!force) {
      final check = await col.limit(1).get();
      if (check.docs.isNotEmpty) return;
    }
    const products = [
      {
        'name': 'Premium Puffer Jacket', 'category': 'JACKETS', 'gender': 'Men',
        'price': 179.0,
        'description': 'Oversized premium puffer with quilted panelling. Water-resistant shell, recycled fill. A streetwear essential built for cold-weather style.',
        'imagePath': 'assets/images/products/Premium Puffer.png',
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'sizeQuantities': {'S': 8, 'M': 10, 'L': 7, 'XL': 5, 'XXL': 3},
        'colors': ['Black', 'Navy', 'Brown', 'Purple'],
        'colorEntries': [
          {'name': 'Black',  'hex': '#000000', 'imageUrl': 'assets/images/products/Premium Puffer.png'},
        ],
        'rating': 4.0, 'reviewCount': 128, 'isNew': false, 'isFeatured': true,
      },
      {
        'name': 'Bomber & Camo Set', 'category': 'SETS', 'gender': 'Women',
        'price': 189.0,
        'description': 'Bold camo bomber paired with matching cargo pants. Military-inspired streetwear at its finest.',
        'imagePath': 'assets/images/products/Bomber & Camo Set.png',
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'sizeQuantities': {'S': 6, 'M': 8, 'L': 5, 'XL': 4, 'XXL': 2},
        'colors': ['Olive', 'Black'],
        'colorEntries': [
          {'name': 'Olive', 'hex': '#6B7028', 'imageUrl': 'assets/images/products/Bomber & Camo Set.png'},
        ],
        'rating': 4.5, 'reviewCount': 86, 'isNew': false, 'isFeatured': true,
      },
      {
        'name': 'Urban Black Ensemble', 'category': 'OUTERWEAR', 'gender': 'Men & Women',
        'price': 249.0,
        'description': 'Street-ready layered look featuring oversized jacket and cargo pants. Urban fashion meets function.',
        'imagePath': 'assets/images/products/Urban Black Ensemble.png',
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'sizeQuantities': {'S': 4, 'M': 6, 'L': 5, 'XL': 3, 'XXL': 1},
        'colors': ['Black', 'Olive'],
        'colorEntries': [
          {'name': 'Black', 'hex': '#000000', 'imageUrl': 'assets/images/products/Urban Black Ensemble.png'},
        ],
        'rating': 4.2, 'reviewCount': 54, 'isNew': false, 'isFeatured': true,
      },
      {
        'name': 'Streetwear Duo Collection', 'category': 'SETS', 'gender': 'Men',
        'price': 299.0,
        'description': 'Complete streetwear duo featuring matching top and bottoms. Perfect for the fashion-forward individual.',
        'imagePath': 'assets/images/products/Streetwear Duo Collection.png',
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'sizeQuantities': {'XS': 3, 'S': 5, 'M': 8, 'L': 4, 'XL': 2},
        'colors': ['Black', 'White'],
        'colorEntries': [
          {'name': 'Black', 'hex': '#000000', 'imageUrl': 'assets/images/products/Streetwear Duo Collection.png'},
        ],
        'rating': 4.8, 'reviewCount': 32, 'isNew': true, 'isFeatured': false,
      },
      {
        'name': 'Lightning Track Set', 'category': 'SETS', 'gender': 'Men & Women',
        'price': 149.0,
        'description': 'Electric lightning-print track set. Lightweight, breathable, and built for the streets.',
        'imagePath': 'assets/images/products/Lightning Track Set.png',
        'sizes': ['S', 'M', 'L', 'XL'],
        'sizeQuantities': {'S': 7, 'M': 9, 'L': 6, 'XL': 3},
        'colors': ['Red', 'Black', 'Blue'],
        'colorEntries': [
          {'name': 'Red', 'hex': '#D32F2F', 'imageUrl': 'assets/images/products/Lightning Track Set.png'},
        ],
        'rating': 4.3, 'reviewCount': 67, 'isNew': true, 'isFeatured': false,
      },
      {
        'name': 'Leopard Print Shirt', 'category': 'SHIRTS', 'gender': 'Men & Women',
        'price': 89.0,
        'description': 'Bold leopard-print button-up shirt. Make a statement with this wild streetwear piece.',
        'imagePath': 'assets/images/products/Leopard Print Shirt.png',
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'sizeQuantities': {'XS': 4, 'S': 6, 'M': 8, 'L': 5, 'XL': 3},
        'colors': ['Brown', 'Black'],
        'colorEntries': [
          {'name': 'Brown', 'hex': '#8B5E3C', 'imageUrl': 'assets/images/products/Leopard Print Shirt.png'},
        ],
        'rating': 4.1, 'reviewCount': 41, 'isNew': true, 'isFeatured': false,
      },
    ];
    for (final p in products) await col.add(p);
  }
}