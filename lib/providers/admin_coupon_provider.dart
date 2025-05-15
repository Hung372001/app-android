import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/coupon_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AdminCouponProvider with ChangeNotifier {
  final String baseUrl = '${AppConstants.baseUrl}/coupons';
  final AuthProvider _authProvider;

  AdminCouponProvider(this._authProvider);

  // State variables
  List<Coupon> _coupons = [];
  bool _isLoading = false;
  bool _hasMoreCoupons = true;
  int _currentPage = 1;
  String? _errorMessage;

  // Getters
  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  bool get hasMoreCoupons => _hasMoreCoupons;
  String? get errorMessage => _errorMessage;

  // Fetch coupons with search and filter capabilities
  Future<void> fetchCoupons({
    String? searchQuery,
    bool activeOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    if (page == 1) {
      _isLoading = true;
      _currentPage = 1;
    }

    notifyListeners();

    try {
      // Prepare query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        if (activeOnly) 'activeOnly': 'true',
      };

      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Make API request
      final response = await http.get(
        Uri.parse(baseUrl).replace(queryParameters: queryParams),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final List<dynamic> couponList = responseData['coupons'];
        final List<Coupon> fetchedCoupons = couponList
            .map((coupon) => Coupon.fromJson(coupon))
            .toList();

        // If first page, replace the list, otherwise add to it
        if (page == 1) {
          _coupons = fetchedCoupons;
        } else {
          _coupons.addAll(fetchedCoupons);
        }

        // Check if there are more coupons to load
        _hasMoreCoupons = fetchedCoupons.length == limit;
        _currentPage = page;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load coupons. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more coupons for pagination
  Future<void> loadMoreCoupons() async {
    if (!_hasMoreCoupons || _isLoading) return;

    await fetchCoupons(page: _currentPage + 1);
  }

  // Create a new coupon
  Future<bool> createCoupon(Coupon coupon) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token


      // Make API request
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(coupon.toJson()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final newCoupon = Coupon.fromJson(responseData['coupon']);

        // Add to the list
        _coupons.insert(0, newCoupon);
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create coupon. Please try again.';
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

  // Update an existing coupon
  Future<bool> updateCoupon(Coupon coupon) async {
    if (coupon.id == null) {
      _errorMessage = 'Coupon ID is required for update';
      notifyListeners();
      return false;
    }

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
      final response = await http.put(
        Uri.parse('$baseUrl/${coupon.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(coupon.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedCoupon = Coupon.fromJson(responseData['coupon']);

        // Update in the list
        final index = _coupons.indexWhere((c) => c.id == coupon.id);
        if (index != -1) {
          _coupons[index] = updatedCoupon;
        }

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update coupon. Please try again.';
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

  // Delete a coupon
  Future<bool> deleteCoupon(String couponId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token
      final token = _authProvider.authToken;
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      print('Deleting coupon with ID: $couponId');
      // Make API request
      final response = await http.delete(
        Uri.parse('$baseUrl/$couponId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from the list
        _coupons.removeWhere((coupon) => coupon.id == couponId);
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete coupon. Please try again.';
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