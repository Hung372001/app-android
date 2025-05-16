import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AdminOrderProvider with ChangeNotifier {
  final String baseUrl = '${AppConstants.baseUrl}/orders';
  final AuthProvider _authProvider;

  AdminOrderProvider(this._authProvider);

  // State variables
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _hasMoreOrders = true;
  int _currentPage = 1;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get hasMoreOrders => _hasMoreOrders;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Set date range for filtering
  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  // Clear date range filter
  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Fetch orders with search, filter, and pagination
  Future<void> fetchOrders({
    String? status,
    String? searchQuery,
    int page = 1,
    int limit = 10,
  }) async {
    if (page == 1) {
      _isLoading = true;
      _currentPage = 1;
      _orders = [];
    }

    notifyListeners();

    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Prepare query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        if (status != null) 'status': status,
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
      };

      // Make API request
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode }');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final List<dynamic> orderList = responseData['orders'];
        print('Response status 3: ${orderList}');

        final List<Order> fetchedOrders = orderList
            .map((order) => Order.fromJson(order))
            .toList();
        print('Response status 3: ${fetchedOrders}');

        // If first page, replace the list, otherwise add to it

        // Check if there are more orders to load
        // final int totalOrders = responseData['totalOrders'] ?? 0;
        // _hasMoreOrders = totalOrders > _orders.length;
        _currentPage = page;
        _errorMessage = null;
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to load orders';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more orders for pagination
  Future<void> loadMoreOrders() async {
    if (!_hasMoreOrders || _isLoading) return;

    await fetchOrders(page: _currentPage + 1);
  }

  // Get a specific order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Make API request
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Order.fromJson(responseData['order']);
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to get order details';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Make API request
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedOrder = Order.fromJson(responseData['order']);

        // Update in the list
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to update order status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Prepare query parameters
      final queryParams = {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      // Make API request
      final response = await http.get(
        Uri.parse('$baseUrl/statistics').replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to get order statistics';
        return {};
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return {};
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Make API request
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedOrder = Order.fromJson(responseData['order']);

        // Update in the list
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Handle error response
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to cancel order';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}