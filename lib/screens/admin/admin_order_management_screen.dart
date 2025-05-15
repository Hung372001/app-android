import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../providers/admin_order_provider.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  String _selectedStatus = 'All';

  // Status options for filtering
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusOptions.length, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _statusOptions[_tabController.index];
        });
        _refreshOrders();
      }
    });

    // Fetch initial orders when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();

      // Add scroll listener for pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // Load more orders when scrolled to the bottom
          final orderProvider = Provider.of<AdminOrderProvider>(context, listen: false);
          orderProvider.loadMoreOrders();
        }
      });
    });
  }

  void _refreshOrders() {
    final orderProvider = Provider.of<AdminOrderProvider>(context, listen: false);
    final status = _selectedStatus == 'All' ? null : _selectedStatus;
    orderProvider.fetchOrders(status: status);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Update Order Status
  void _showUpdateStatusDialog(BuildContext context, Order order) {
    String selectedStatus = order.status;

    // Get available status options based on current status
    List<String> availableStatuses = _getNextPossibleStatuses(order.status);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Cập nhật trạng thái đơn hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đơn hàng #${order.orderNumber}'),
              Text('Trạng thái hiện tại: ${order.status}'),
              SizedBox(height: 16),
              Text('Chọn trạng thái mới:'),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: availableStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
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
                if (selectedStatus != order.status) {
                  // Perform update operation
                  final orderProvider = Provider.of<AdminOrderProvider>(context, listen: false);
                  orderProvider.updateOrderStatus(order.id, selectedStatus);
                }
                Navigator.of(context).pop();
              },
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  // Get next possible statuses based on current status
  List<String> _getNextPossibleStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return ['Pending', 'Processing', 'Cancelled'];
      case 'Processing':
        return ['Processing', 'Shipped', 'Cancelled'];
      case 'Shipped':
        return ['Shipped', 'Delivered', 'Cancelled'];
      case 'Delivered':
        return ['Delivered']; // Final state
      case 'Cancelled':
        return ['Cancelled']; // Final state
      default:
        return ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
    }
  }

  // Show order details dialog
  void _showOrderDetailsDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết đơn hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Order info scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      _buildSectionHeader(context, 'Thông tin đơn hàng'),
                      _buildInfoRow('Mã đơn hàng:', '#${order.orderNumber}'),
                      _buildInfoRow('Ngày đặt:', DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)),
                      _buildStatusChip(context, order.status),
                      SizedBox(height: 24),

                      // Customer Info
                      _buildSectionHeader(context, 'Thông tin khách hàng'),
                      _buildInfoRow('Họ tên:', order.customerName),
                      _buildInfoRow('Email:', order.customerEmail),
                      _buildInfoRow('Điện thoại:', order.customerPhone),
                      SizedBox(height: 24),

                      // Shipping Address
                      _buildSectionHeader(context, 'Địa chỉ giao hàng'),
                      Text(order.shippingAddress),
                      SizedBox(height: 24),

                      // Payment Info
                      _buildSectionHeader(context, 'Thông tin thanh toán'),
                      _buildInfoRow('Phương thức:', order.paymentMethod),
                      Row(
                        children: [
                          Text('Trạng thái:'),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.paymentStatus == 'Paid' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.paymentStatus,
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Order Items
                      _buildSectionHeader(context, 'Sản phẩm đã đặt'),
                      ...order.items.map((item) => _buildOrderItem(context, item)),
                      SizedBox(height: 24),

                      // Order Summary
                      _buildSectionHeader(context, 'Tổng kết đơn hàng'),
                      _buildSummaryRow('Tạm tính:', '${order.subtotal.toStringAsFixed(0)}đ'),
                      if (order.couponCode != null && order.discountAmount > 0)
                        _buildSummaryRow(
                          'Giảm giá (${order.couponCode}):',
                          '-${order.discountAmount.toStringAsFixed(0)}đ',
                        ),
                      _buildSummaryRow('Phí vận chuyển:', '${order.shippingFee.toStringAsFixed(0)}đ'),
                      Divider(thickness: 1),
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

              // Action buttons
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Đóng'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showUpdateStatusDialog(context, order);
                      },
                      child: Text('Cập nhật trạng thái'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Divider(),
        SizedBox(height: 8),
      ],
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build status chip
  Widget _buildStatusChip(BuildContext context, String status) {
    Color statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Trạng thái:',
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build order items
  Widget _buildOrderItem(BuildContext context, OrderItem item) {
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
                    'Phiên bản: ${item.variantName}',
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

  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusOptions.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã đơn hàng hoặc tên khách hàng...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshOrders();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                // Perform search
                if (value.isNotEmpty) {
                  final status = _selectedStatus == 'All' ? null : _selectedStatus;
                  final orderProvider = Provider.of<AdminOrderProvider>(context, listen: false);
                  orderProvider.fetchOrders(status: status, searchQuery: value);
                }
              },
            ),
          ),

          // Date Range Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Lọc theo ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Expanded(
                  child: Consumer<AdminOrderProvider>(
                    builder: (context, orderProvider, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(orderProvider.startDate != null
                                ? DateFormat('dd/MM/yyyy').format(orderProvider.startDate!)
                                : 'Từ ngày'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: orderProvider.startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                orderProvider.setDateRange(startDate: date, endDate: orderProvider.endDate);
                                _refreshOrders();
                              }
                            },
                          ),
                          Text('-'),
                          TextButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(orderProvider.endDate != null
                                ? DateFormat('dd/MM/yyyy').format(orderProvider.endDate!)
                                : 'Đến ngày'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: orderProvider.endDate ?? DateTime.now(),
                                firstDate: orderProvider.startDate ?? DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                orderProvider.setDateRange(startDate: orderProvider.startDate, endDate: date);
                                _refreshOrders();
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () {
                              orderProvider.clearDateRange();
                              _refreshOrders();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Order List
          Expanded(
            child: Consumer<AdminOrderProvider>(
              builder: (context, orderProvider, child) {
                // Show loading indicator while fetching orders
                if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                // Show message if no orders
                if (orderProvider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy đơn hàng nào',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 8),
                        if (_searchController.text.isNotEmpty || orderProvider.startDate != null)
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              orderProvider.clearDateRange();
                              _refreshOrders();
                            },
                            child: Text('Xóa bộ lọc'),
                          ),
                      ],
                    ),
                  );
                }

                // Order List
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: orderProvider.orders.length +
                      (orderProvider.hasMoreOrders ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == orderProvider.orders.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final order = orderProvider.orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () => _showOrderDetailsDialog(context, order),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order header with status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Đơn hàng #${order.orderNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                ],
                              ),
                              SizedBox(height: 8),

                              // Order info
                              Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
                              Text('Khách hàng: ${order.customerName}'),

                              // Payment info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Thanh toán: ${order.paymentMethod}'),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: order.paymentStatus == 'Paid' ? Colors.green : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.paymentStatus,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Order items summary
                              SizedBox(height: 8),
                              Text('${order.items.length} sản phẩm · ${order.total.toStringAsFixed(0)}đ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              // Action buttons
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.visibility),
                                    label: Text('Xem chi tiết'),
                                    onPressed: () => _showOrderDetailsDialog(context, order),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.update),
                                    label: Text('Cập nhật'),
                                    onPressed: () => _showUpdateStatusDialog(context, order),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get color based on status
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
}