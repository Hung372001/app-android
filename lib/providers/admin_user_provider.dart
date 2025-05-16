import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // Import class User từ user_model.dart
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AdminUserProvider with ChangeNotifier {
  final String baseUrl = '${AppConstants.baseUrl}/users';
  final AuthProvider _authProvider;

  AdminUserProvider(this._authProvider);

  // State variables
  List<User> _users = [];
  bool _isLoading = false;
  bool _hasMoreUsers = true;
  int _currentPage = 1;
  String? _errorMessage;

  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get hasMoreUsers => _hasMoreUsers;
  String? get errorMessage => _errorMessage;

  // Fetch users with search and filter capability
  Future<void> fetchUsers({
    String? searchQuery,
    String? roleFilter,
    int page = 1,
    int limit = 10,
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
        if (roleFilter != null && roleFilter.isNotEmpty) 'role': roleFilter,
      };

      // Get auth token
      // Make API request
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print('Fetched users: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final List<dynamic> userList = responseData['users'];

        final List<User> fetchedUsers = userList
            .map((user) => User.fromJson(user))
            .toList();

        // If first page, replace the list, otherwise add to it
        if (page == 1) {
          _users = fetchedUsers;
        } else {
          _users.addAll(fetchedUsers);
        }

        // Check if there are more users to load
        _hasMoreUsers = fetchedUsers.length == limit;
        _currentPage = page;
        _errorMessage = null;
      } else {
        _errorMessage = 'Không thể tải danh sách người dùng. Vui lòng thử lại.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more users for pagination
  Future<void> loadMoreUsers({
    String? searchQuery,
    String? roleFilter,
  }) async {
    if (!_hasMoreUsers || _isLoading) return;

    await fetchUsers(
      page: _currentPage + 1,
      searchQuery: searchQuery,
      roleFilter: roleFilter,
    );
  }

  // Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token


      // Make API request
      final response = await http.patch(
        Uri.parse('$baseUrl/$userId/role'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedUser = User.fromJson(responseData['user']);

        // Update in the list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
        }

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Không thể cập nhật quyền người dùng. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
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
      final response = await http.delete(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from the list
        _users.removeWhere((user) => user.id == userId);
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Không thể xóa người dùng. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user details
  Future<bool> updateUser(User user) async {
    if (user.id.isEmpty) {
      _errorMessage = 'ID người dùng là bắt buộc';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token
      final token = _authProvider.authToken;


      // Make API request
      final response = await http.put(
        Uri.parse('$baseUrl/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedUser = User.fromJson(responseData['user']);

        // Update in the list
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = updatedUser;
        }

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Không thể cập nhật thông tin người dùng. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}