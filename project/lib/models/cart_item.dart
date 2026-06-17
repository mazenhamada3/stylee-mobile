//one product inside the cart
class CartItem {
  final String productId;
  final String name;
  final String category;
  final double price;
  final String imagePath;
  final String size;
  final String color;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    required this.size,
    required this.color,
    this.quantity = 1,
  });

  double get total => price * quantity;

  String get cartKey => '${productId}_${size}_$color';

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'category': category,
    'price': price,
    'imagePath': imagePath,
    'size': size,
    'color': color,
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    productId: m['productId'] ?? '',
    name: m['name'] ?? '',
    category: m['category'] ?? '',
    price: (m['price'] as num).toDouble(),
    imagePath: m['imagePath'] ?? '',
    size: m['size'] ?? '',
    color: m['color'] ?? '',
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}