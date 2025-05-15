import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';

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
}

class CartProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  CartProvider(this._authProvider);

  // Cart items
  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  // Calculate total cart value
  double get totalAmount {
    return _items.fold(0, (total, item) => total + item.totalPrice);
  }

  // Calculate total items in cart
  int get totalItems {
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  List<OrderCartItem> getOrderCartItems() {
    return items.map((item) => OrderCartItem(
      productId: item.product.id,
      productName: item.product.name,
      variantId: item.variant.id,
      variantName: item.variant.name,
      price: item.variant.price,
      quantity: item.quantity,
      imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null,
    )).toList();
  }
  // Add item to cart
  void addToCart({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    // Check if product with same variant already exists in cart
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].product.id == product.id &&
          _items[i].variant.id == variant.id) {
        // Update quantity if product already in cart
        _items[i] = _items[i].copyWith(
            quantity: _items[i].quantity + quantity
        );
        notifyListeners();
        return;
      }
    }

    // Add new item to cart
    _items.add(CartItem(
      product: product,
      variant: variant,
      quantity: quantity,
    ));
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(cartItem);
    } else {
      final index = _items.indexOf(cartItem);
      if (index != -1) {
        _items[index] = cartItem.copyWith(quantity: newQuantity);
        notifyListeners();
      }
    }
  }

  // Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Apply coupon (placeholder method)
  double applyCoupon(String couponCode) {
    // TODO: Implement coupon logic
    // This is a placeholder method that needs to be implemented
    // based on specific coupon validation rules
    return 0.0;
  }

  // Calculate shipping fee
  double calculateShippingFee() {
    // Example shipping fee calculation
    // You can implement more complex logic based on total amount, location, etc.
    return totalAmount > 1000000 ? 0 : 50000;
  }

  // Calculate total with shipping and potential discounts
  double calculateTotalWithShipping() {
    return totalAmount + calculateShippingFee();
  }
}