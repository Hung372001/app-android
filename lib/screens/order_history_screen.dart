import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../utils/routes.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  bool _hasMoreOrders = true;
  String? _errorMessage;
  late TabController _tabController;

  // List of orders
  List<Order> _orders = [];

  // Status options for tabs
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];
  String _selectedStatus = 'All';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusOptions.length, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _statusOptions[_tabController.index];
          _isLoading = true;
          _orders = [];
          _hasMoreOrders = true;
        });
        _loadOrders();
      }
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load initial orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        !_loadingMore &&
        _hasMoreOrders) {
      _loadMoreOrders();
    }
  }

  // Load initial orders
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final result = await orderProvider.getOrderHistory(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      );

      setState(() {
        _orders = result.orders;
        _hasMoreOrders = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Load more orders for pagination
  Future<void> _loadMoreOrders() async {
    if (_loadingMore || !_hasMoreOrders) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final result = await orderProvider.getOrderHistory(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        page: (_orders.length ~/ 10) + 1, // Assuming 10 items per page
      );

      setState(() {
        _orders.addAll(result.orders);
        _hasMoreOrders = result.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loadingMore = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thêm đơn hàng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusOptions.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: _hasError
          ? _buildErrorView()
          : _isLoading
          ? _buildLoadingView()
          : _orders.isEmpty
          ? _buildEmptyView()
          : _buildOrderList(),
    );
  }

  // Loading indicator
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải đơn hàng...'),
        ],
      ),
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
              _errorMessage ?? 'Không thể tải danh sách đơn hàng',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              child: Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // Empty view
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bạn chưa có đơn hàng nào${_selectedStatus != 'All' ? ' trong trạng thái $_selectedStatus' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.shopping_bag),
              label: Text('Mua sắm ngay'),
              onPressed: () {
                Navigator.pushNamed(context, Routes.productCatalog);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Order list view
  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _orders.length + (_hasMoreOrders ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Order card widget
  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.orderDetails,
            arguments: order.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Order date
              Text(
                'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Divider(height: 16),

              // Order items summary
              Text(
                '${order.items.length} sản phẩm - ${order.total.toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // First item preview
              if (order.items.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                        image: order.items.first.imageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(order.items.first.imageUrl!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: order.items.first.imageUrl == null
                          ? Icon(Icons.image_not_supported, color: Colors.grey, size: 20)
                          : null,
                    ),
                    SizedBox(width: 8),

                    // Product name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.items.first.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${order.items.first.price.toStringAsFixed(0)}đ x ${order.items.first.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // More items indicator
              if (order.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+${order.items.length - 1} sản phẩm khác',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),

              SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.orderDetails,
                        arguments: order.id,
                      );
                    },
                    child: Text('Xem chi tiết'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (order.status == 'Pending')
                    ElevatedButton(
                      onPressed: () {
                        _showCancelDialog(order);
                      },
                      child: Text('Hủy đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show cancel order confirmation dialog
  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy đơn hàng'),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng #${order.orderNumber}? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Cancel order
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.cancelOrder(order.id);

                // Reload orders
                _loadOrders();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đơn hàng đã được hủy thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
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
}