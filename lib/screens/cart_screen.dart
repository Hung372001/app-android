import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/routes.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Cart'),
        actions: [
          // Nút xóa tất cả
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearCartConfirmation(context);
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.items;

          // Kiểm tra giỏ hàng trống
          if (cartItems.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Danh sách sản phẩm trong giỏ hàng
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    return _buildCartItem(context, cartItem, cartProvider);
                  },
                ),
              ),

              // Thông tin thanh toán
              _buildCheckoutSection(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  // Widget hiển thị khi giỏ hàng trống
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Add items to your cart to see them here',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.shopping_bag),
            label: Text('Continue Shopping'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Widget hiển thị mỗi sản phẩm trong giỏ hàng
  Widget _buildCartItem(BuildContext context, CartItem cartItem, CartProvider cartProvider) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: cartItem.product.imageUrls.isNotEmpty
                    ? Image.network(
                  cartItem.product.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12),

            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    cartItem.product.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // Biến thể (nếu có)
                  if (cartItem.variant.name != 'Default')
                    Text(
                      'Variant: ${cartItem.variant.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                  // Giá sản phẩm
                  Text(
                    '${cartItem.variant.price.toStringAsFixed(0)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  // Bộ chọn số lượng
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          if (cartItem.quantity > 1) {
                            cartProvider.updateQuantity(cartItem, cartItem.quantity - 1);
                          } else {
                            // Xác nhận xóa sản phẩm
                            _showRemoveItemConfirmation(context, cartItem, cartProvider);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${cartItem.quantity}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          cartProvider.updateQuantity(cartItem, cartItem.quantity + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tổng giá và nút xóa
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${cartItem.totalPrice.toStringAsFixed(0)}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showRemoveItemConfirmation(context, cartItem, cartProvider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Phần thanh toán dưới cùng
  Widget _buildCheckoutSection(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Column(
        children: [
          // Tóm tắt đơn hàng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal'),
              Text(
                '${cartProvider.totalAmount.toStringAsFixed(0)}đ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Fee'),
              Text(
                '${cartProvider.calculateShippingFee().toStringAsFixed(0)}đ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${cartProvider.calculateTotalWithShipping().toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Nút Checkout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Chuyển đến màn hình thanh toán
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Checkout feature will be implemented soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hộp thoại xác nhận xóa sản phẩm
  void _showRemoveItemConfirmation(BuildContext context, CartItem cartItem, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Item'),
        content: Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.removeFromCart(cartItem);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Item removed from cart'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  // Hộp thoại xác nhận xóa tất cả
  void _showClearCartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}