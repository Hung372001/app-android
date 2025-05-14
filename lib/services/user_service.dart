import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../utils/constants.dart';

class LoginResponse {
  final User user;
  final String token;

  LoginResponse({required this.user, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }
}

class UserService {
  // Login User
  Future<LoginResponse?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        print('Login successful: ${response.body}');
        return LoginResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register User
  Future<LoginResponse?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String shippingAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'shippingAddress': shippingAddress,
        }),
      );

      if (response.statusCode == 201) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Get User Details
  Future<User?> getUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header here in a real app
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get user details error: $e');
      return null;
    }
  }

  // Update Profile
  Future<User?> updateProfile({
    required String userId,
    required String fullName,
    required String shippingAddress,
    String? profileImageUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header here in a real app
        },
        body: jsonEncode({
          'fullName': fullName,
          'shippingAddress': shippingAddress,
          'profileImageUrl': profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }

  // Change Password
  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header here in a real app
        },
        body: jsonEncode({
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  // Recover Password
  Future<bool> recoverPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/recover-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Recover password error: $e');
      return false;
    }
  }
}