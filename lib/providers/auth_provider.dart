import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Google SignIn instance

  // Getters
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser != null && _currentUser!.isAdmin; // Sử dụng getter isAdmin từ model User
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update Profile Method
  Future<bool> updateProfile({
    required String fullName,
    required String shippingAddress,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/${_currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'fullName': fullName,
          'shippingAddress': shippingAddress,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        // Update local user object
        _currentUser = User(
          id: _currentUser!.id,
          fullName: fullName,
          email: _currentUser!.email,
          role: _currentUser!.role,
          shippingAddress: shippingAddress,
        );

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Change Password Method
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'userId': _currentUser!.id,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to change password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error changing password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Login method with role support
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Parse user and token from API response
        _currentUser = User.fromJson(responseData['user']);
        _authToken = responseData['token'];

        notifyListeners();
        return true;
      } else {
        // Parse error message from API
        _errorMessage = json.decode(response.body)['message'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Logout method
  void logout() {
    _currentUser = null;
    _authToken = null;
    _isLoading = false;
    _errorMessage = null;

    // Đăng xuất khỏi Google nếu đã đăng nhập

    notifyListeners();
  }

  // Registration method
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String shippingAddress,
    String? phone, // Vẫn nhận phone từ tham số nhưng không lưu
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'shippingAddress': shippingAddress,
          // Không gửi phone vì model không có
        }),
      );

      _isLoading = false;

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Parse user and token
        _currentUser = User.fromJson(responseData['user']);
        _authToken = responseData['token'];
        _errorMessage = null;

        notifyListeners();
        return true;
      } else {
        // Xử lý lỗi chi tiết từ API
        try {
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Đăng ký thất bại';
        } catch (e) {
          _errorMessage = 'Đăng ký thất bại';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng ký: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Password recovery method
  Future<bool> recoverPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/recover-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Password recovery failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Password recovery error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }


}