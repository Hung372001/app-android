import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

// Class to hold coupon validation result
class CouponValidationResult {
  final bool isValid;
  final String? message;
  final double discountAmount;

  CouponValidationResult({
    required this.isValid,
    this.message,
    required this.discountAmount,
  });
}

// Class to hold order history result
class OrderHistoryResult {
  final List<Order> orders;
  final bool hasMore;

  OrderHistoryResult({
    required this.orders,
    required this.hasMore,
  });
}

class OrderProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final String baseUrl = '${AppConstants.baseUrl}/orders';

  OrderProvider(this._authProvider);

  // Create a new order
  Future<Order> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    required String paymentMethod,
    required List<CartItem> cartItems,
    String? couponCode,
    required double discountAmount,
    required double shippingFee,
    required double subtotal,
    required double total,
  }) async {
    // Check authentication
    final token = _authProvider.authToken;
    if (token == null) {
      throw Exception('You must be logged in to create an order');
    }

    try {
      // Prepare order items from cart items
      final List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        return {
          'productId': item.product.id,
          'productName': item.product.name,
          'variantName': item.variant.name,
          'price': item.variant.price,
          'quantity': item.quantity,
          'imageUrl': item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null,
        };
      }).toList();

      // Create order payload
      final Map<String, dynamic> orderData = {
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'items': orderItems,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discountAmount': discountAmount,
        'total': total,
      };

      // Add coupon code if available
      if (couponCode != null && couponCode.isNotEmpty) {
        orderData['couponCode'] = couponCode;
      }

      // Send API request
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        // Parse and return the created order
        final responseData = json.decode(response.body);
        return Order.fromJson(responseData['order']);
      } else {
        // Handle API error
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Error creating order: ${e.toString()}');
    }
  }

  // Validate a coupon code
  Future<CouponValidationResult> validateCoupon(String couponCode, double orderAmount) async {
    try {
      // Get authentication token if available
      final token = _authProvider.authToken;

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Send API request
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/coupons/validate'),
        headers: headers,
        body: json.encode({
          'code': couponCode,
          'orderAmount': orderAmount,
        }),
      );

      if (response.statusCode == 200) {
        // Parse successful validation
        final responseData = json.decode(response.body);
        return CouponValidationResult(
          isValid: true,
          discountAmount: responseData['discountAmount']?.toDouble() ?? 0.0,
        );
      } else {
        // Parse validation error
        final errorData = json.decode(response.body);
        return CouponValidationResult(
          isValid: false,
          message: errorData['message'] ?? 'Mã giảm giá không hợp lệ',
          discountAmount: 0.0,
        );
      }
    } catch (e) {
      // Handle any other errors
      return CouponValidationResult(
        isValid: false,
        message: 'Lỗi khi kiểm tra mã giảm giá: ${e.toString()}',
        discountAmount: 0.0,
      );
    }
  }

  // Get order history
  Future<OrderHistoryResult> getOrderHistory({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    // Check authentication


    try {
      // Prepare query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add status filter if provided
      if (status != null && status != 'All') {
        queryParams['status'] = status;
      }

      // Send API request
      final response = await http.get(
        Uri.parse(baseUrl).replace(queryParameters: queryParams),

      );

      if (response.statusCode == 200) {
        // Parse successful response
        final responseData = json.decode(response.body);

        // Extract orders
        final List<dynamic> ordersData = responseData['orders'];
        final List<Order> orders = ordersData
            .map((orderData) => Order.fromJson(orderData))
            .toList();

        // Extract pagination info
        final int totalOrders = responseData['totalOrders'] ?? 0;
        final bool hasMore = totalOrders > page * limit;

        return OrderHistoryResult(
          orders: orders,
          hasMore: hasMore,
        );
      } else {
        // Handle API error
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load order history');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Error loading order history: ${e.toString()}');
    }
  }

  // Get order details
  Future<Order> getOrderDetails(String orderId) async {
    // Check authentication
    final token = _authProvider.authToken;


    try {
      // Send API request
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Parse successful response
        final responseData = json.decode(response.body);
        return Order.fromJson(responseData['order']);
      } else {
        // Handle API error
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load order details');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Error loading order details: ${e.toString()}');
    }
  }

  // Cancel an order
  Future<void> cancelOrder(String orderId) async {
    // Check authentication
    final token = _authProvider.authToken;


    try {
      // Send API request
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        // Handle API error
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Error cancelling order: ${e.toString()}');
    }
  }
}