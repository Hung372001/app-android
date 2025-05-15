import '../models/product_model.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  // Calculate total price for this cart item
  double get totalPrice => variant.price * quantity;

  // Create a copy of the cart item
  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }

  // Convert cart item to a map for order creation
  Map<String, dynamic> toOrderItem() {
    return {
      'productId': product.id,
      'productName': product.name,
      'variantName': variant.name,
      'price': variant.price,
      'quantity': quantity,
      'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
    };
  }
}