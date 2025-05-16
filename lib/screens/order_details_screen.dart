import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../utils/routes.dart';

class OrderDetailsScreen extends StatefulWidget {
  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  Order? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load order details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
    });
  }

  Future<void> _loadOrderDetails() async {
    final String orderId = ModalRoute.of(context)!.settings.arguments as String;

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = await orderProvider.getOrderDetails(orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải thông tin đơn hàng: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _order == null
          ? _buildOrderNotFound()
          : _buildOrderDetails(),
    );
  }

  // Error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadOrderDetails();
              },
              child: Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // Order not found view
  Widget _buildOrderNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Đơn hàng này không tồn tại hoặc đã bị xóa',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  // Order details view
  Widget _buildOrderDetails() {
    final order = _order!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Status Card
          Card(
            elevation: 4,
            color: _getStatusColor(order.status).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái đơn hàng',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getStatusDescription(order.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin đơn hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    'Mã đơn hàng:',
                    '#${order.orderNumber}',
                    isBold: true,
                  ),
                  _buildInfoRow(
                    'Ngày đặt:',
                    DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
                  ),
                  _buildInfoRow(
                    'Phương thức thanh toán:',
                    order.paymentMethod,
                  ),
                  _buildInfoRow(
                    'Trạng thái giao hàng:',
                    order.paymentStatus,
                    valueColor: order.paymentStatus == 'Paid'
                        ? Colors.green
                        : Colors.orange,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Shipping Address Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    order.shippingAddress,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(order.customerPhone),
                  SizedBox(height: 4),
                  Text(order.customerEmail),
                  SizedBox(height: 8),
                  Text(order.shippingAddress),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order Items Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sản phẩm đã đặt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItem(item)),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan đơn hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  _buildSummaryRow('Tạm tính:', '${order.subtotal.toStringAsFixed(0)}đ'),
                  if (order.couponCode != null && order.discountAmount > 0)
                    _buildSummaryRow(
                      'Giảm giá (${order.couponCode}):',
                      '-${order.discountAmount.toStringAsFixed(0)}đ',
                      valueColor: Colors.green,
                    ),
                  _buildSummaryRow('Phí vận chuyển:', '${order.shippingFee.toStringAsFixed(0)}đ'),
                  Divider(height: 24),
                  _buildSummaryRow(
                    'Tổng cộng:',
                    '${order.total.toStringAsFixed(0)}đ',
                    isBold: true,
                    valueColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Action Buttons
          order.status == 'Pending'
              ? ElevatedButton.icon(
            icon: Icon(Icons.cancel),
            label: Text('Hủy đơn hàng'),
            onPressed: () => _showCancelDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          )
              : SizedBox(),
          SizedBox(height: 16),
          OutlinedButton.icon(
            icon: Icon(Icons.shopping_bag),
            label: Text('Tiếp tục mua sắm'),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.productCatalog,
                    (route) => route.settings.name == Routes.home,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  // Show cancel order confirmation dialog
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy đơn hàng'),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading
              setState(() {
                _isLoading = true;
              });

              try {
                // Cancel order
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.cancelOrder(_order!.id);

                // Reload order details
                await _loadOrderDetails();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đơn hàng đã được hủy thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Không thể hủy đơn hàng: ${e.toString()}';
                });

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không thể hủy đơn hàng: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Hủy đơn hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontSize: isBold ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build order items
  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null
                  ? DecorationImage(
                image: NetworkImage(item.imageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: item.imageUrl == null
                ? Icon(Icons.image_not_supported, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.variantName != null && item.variantName!.isNotEmpty)
                  Text(
                    'Loại: ${item.variantName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(0)}đ x ${item.quantity}',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${(item.price * item.quantity).toStringAsFixed(0)}đ',
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.indigo;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Processing':
        return Icons.inventory;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Helper method to get status description
  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Đơn hàng của bạn đang chờ xác nhận';
      case 'Processing':
        return 'Đơn hàng của bạn đang được xử lý';
      case 'Shipped':
        return 'Đơn hàng của bạn đã được giao cho đơn vị vận chuyển';
      case 'Delivered':
        return 'Đơn hàng của bạn đã được giao thành công';
      case 'Cancelled':
        return 'Đơn hàng của bạn đã bị hủy';
      default:
        return 'Trạng thái đơn hàng không xác định';
    }
  }
}