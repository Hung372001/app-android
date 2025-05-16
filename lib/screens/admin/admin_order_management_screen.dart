import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
// import 'admin_order_detail_screen.dart'; // You'll need to create this screen

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Order> _orders = [];

  // Text controller for email input
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set email from current user if logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.currentUser?.email != null) {
      _emailController.text = authProvider.currentUser!.email;
      _loadOrderHistory();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Load order history using email
  Future<void> _loadOrderHistory() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final orders = await orderProvider.getOrderHistoryByEmail('');

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Hiển thị hộp thoại cập nhật trạng thái đơn hàng
  void _showUpdateStatusDialog(BuildContext context, Order order) {
    // Tạo biến status để bảo đảm dữ liệu khớp với các lựa chọn
    String selectedStatus = order.status;

    // Kiểm tra và chuẩn hóa giá trị ban đầu để chắc chắn nó khớp với một trong các tùy chọn
    if (!['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].contains(selectedStatus)) {
      // Nếu giá trị không khớp, đặt một giá trị mặc định
      selectedStatus = 'Pending';
    }

    // Định nghĩa các trạng thái có thể chọn
    final List<Map<String, String>> statusOptions = [
      {'value': 'Pending', 'label': 'Chờ xác nhận'},
      {'value': 'Processing', 'label': 'Đang xử lý'},
      {'value': 'Shipped', 'label': 'Đang giao'},
      {'value': 'Delivered', 'label': 'Đã giao'},
      {'value': 'Cancelled', 'label': 'Đã hủy'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Cập nhật trạng thái đơn hàng'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã đơn hàng: #${order.id}'),
                  SizedBox(height: 8),
                  Text('Trạng thái hiện tại: ${_getStatusText(order.status)}'),
                  SizedBox(height: 16),
                  Text('Chọn trạng thái mới:'),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedStatus = newValue!;
                          });
                        },
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status['value'],
                            child: Text(status['label']!),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateOrderStatus(order.id, selectedStatus);
                    Navigator.of(context).pop();
                  },
                  child: Text('Cập nhật'),
                ),
              ],
            );
          }
      ),
    );
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Lấy token từ AuthProvider
      final token = authProvider.authToken;

      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Gọi API cập nhật trạng thái
      final success = await OrderProvider.updateOrderStatus(orderId, newStatus);

      if (success) {
        // Nếu thành công, cập nhật lại danh sách đơn hàng
        await _loadOrderHistory();

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hiển thị lỗi nếu có
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng'),
      ),
      body: Column(
        children: [
          // Email input field (nếu cần thiết)

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Loading indicator or order list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không tìm thấy đơn hàng nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bạn chưa có đơn hàng nào với email này',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderItem(context, order);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build an order item card
  Widget _buildOrderItem(BuildContext context, Order order) {
    // Format order date
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);

    // Get status color
    Color statusColor;
    switch (order.status) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Shipped':
        statusColor = Colors.blue;
        break;
      case 'Processing':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to order details screen
          // Navigator.pushNamed(
          //   context,
          //   Routes.orderDetails,
          //   arguments: order.id,
          // );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              Divider(height: 24),

              // Order items summary
              Text(
                '${order.items.length} sản phẩm',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),

              SizedBox(height: 8),

              // Show first 2 items
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),

              // Show "and more" if there are more than 2 items
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '... và ${order.items.length - 2} sản phẩm khác',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Order total and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền: ${order.total.toStringAsFixed(0)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Nút cập nhật trạng thái
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Đổi trạng thái',
                        onPressed: () {
                          _showUpdateStatusDialog(context, order);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Convert status to Vietnamese
  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';

      case 'Shipped':
        return 'Đang giao';
      case 'Delivered':
        return 'Đã giao';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}