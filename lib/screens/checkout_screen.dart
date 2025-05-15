import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../utils/routes.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _couponController;

  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isCouponApplied = false;
  bool _isCouponValid = false;
  String? _couponError;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _initControllers();
  }

  void _initControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController(text: user?.shippingAddress ?? '');
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  // Apply coupon
  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      setState(() {
        _couponError = 'Vui lòng nhập mã giảm giá';
        _isCouponApplied = false;
        _isCouponValid = false;
        _discountAmount = 0;
      });
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      _isCouponApplied = true;
    });

    // Call provider to validate and apply coupon
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.validateCoupon(
        couponCode,
        cartProvider.totalAmount
    ).then((result) {
      setState(() {
        _isCouponValid = result.isValid;
        _couponError = result.isValid ? null : result.message;
        _discountAmount = result.discountAmount;
        _isCouponApplied = true;
      });
    });
  }

  // Submit order
  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giỏ hàng của bạn đang trống'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create order
      const cartItems = [];

      final order = await orderProvider.createOrder(
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        customerPhone: _phoneController.text,
        shippingAddress: _addressController.text,
        paymentMethod: _selectedPaymentMethod,
        cartItems: cartProvider.items,
        couponCode: _isCouponValid ? _couponController.text : null,
        discountAmount: _discountAmount,
        shippingFee: cartProvider.calculateShippingFee(),
        subtotal: cartProvider.totalAmount,
        total: _calculateTotal(cartProvider),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Clear cart
      cartProvider.clearCart();

      // Navigate to success screen
      Navigator.pushReplacementNamed(
        context,
        Routes.orderSuccess,
        arguments: order,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Calculate total amount with shipping and discount
  double _calculateTotal(CartProvider cartProvider) {
    double total = cartProvider.totalAmount;

    // Add shipping fee
    total += cartProvider.calculateShippingFee();

    // Subtract discount amount (if valid coupon)
    if (_isCouponValid) {
      total -= _discountAmount;

      // Ensure total is not negative
      if (total < 0) total = 0;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Calculate totals
    final subtotal = cartProvider.totalAmount;
    final shippingFee = cartProvider.calculateShippingFee();
    final total = _calculateTotal(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán'),
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyCart()
          : Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Customer Information
                    _buildSectionHeader('Thông tin giao hàng', Icons.person),

                    // Name Field
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Họ và tên',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }

                        // Simple email validation
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Vui lòng nhập email hợp lệ';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Phone Field
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Số điện thoại',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }

                        // Phone must be at least 10 digits
                        if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                          return 'Số điện thoại không hợp lệ';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Address Field
                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Địa chỉ giao hàng',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ giao hàng';
                        }

                        if (value.length < 10) {
                          return 'Vui lòng nhập địa chỉ chi tiết hơn';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Section: Payment Method
                    _buildSectionHeader('Phương thức thanh toán', Icons.payment),

                    // Payment options
                    _buildPaymentOption(
                      'Cash on Delivery',
                      'Thanh toán khi nhận hàng',
                      Icons.money,
                    ),
                    _buildPaymentOption(
                      'Bank Transfer',
                      'Chuyển khoản ngân hàng',
                      Icons.account_balance,
                    ),
                    _buildPaymentOption(
                      'Credit Card',
                      'Thanh toán bằng thẻ tín dụng',
                      Icons.credit_card,
                    ),
                    SizedBox(height: 24),

                    // Section: Apply Coupon
                    _buildSectionHeader('Mã giảm giá', Icons.discount),

                    // Coupon Field with Apply button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: InputDecoration(
                              labelText: 'Nhập mã giảm giá',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              errorText: _isCouponApplied && !_isCouponValid
                                  ? _couponError
                                  : null,
                              suffixIcon: _isCouponValid
                                  ? Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                            enabled: !_isCouponValid,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isCouponValid ? null : _applyCoupon,
                          child: Text(_isCouponValid ? 'Đã áp dụng' : 'Áp dụng'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    if (_isCouponValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Giảm ${_discountAmount.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),

                    // Section: Order Summary
                    _buildSectionHeader('Tổng đơn hàng', Icons.shopping_cart),

                    // Order items summary
                    ...cartProvider.items.map((item) => _buildOrderItemSummary(item)),
                  ],
                ),
              ),
            ),

            // Fixed bottom section: Total and Checkout button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tạm tính:'),
                      Text(
                        '${subtotal.toStringAsFixed(0)}đ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Phí vận chuyển:'),
                      Text(
                        '${shippingFee.toStringAsFixed(0)}đ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_isCouponValid) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giảm giá:'),
                        Text(
                          '-${_discountAmount.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${total.toStringAsFixed(0)}đ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Đặt hàng',
                      onPressed: _submitOrder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty cart placeholder
  Widget _buildEmptyCart() {
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
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thêm sản phẩm vào giỏ hàng để thanh toán',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.shopping_bag),
            label: Text('Tiếp tục mua sắm'),
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.productCatalog);
            },
          ),
        ],
      ),
    );
  }

  // Build a section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Divider(),
        SizedBox(height: 8),
      ],
    );
  }

  // Build a payment option radio button
  Widget _buildPaymentOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue!;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  // Build an order item summary row
  Widget _buildOrderItemSummary(CartItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrls.isNotEmpty
                  ? item.product.imageUrls.first
                  : 'https://via.placeholder.com/60',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variant.name != 'Default')
                  Text(
                    'Loại: ${item.variant.name}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.variant.price.toStringAsFixed(0)}đ x ${item.quantity}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)}đ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}