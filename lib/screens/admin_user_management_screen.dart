import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart'; // Import từ user_model.dart
import '../providers/admin_user_provider.dart';
import '../providers/auth_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    // Fetch initial users when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
      userProvider.fetchUsers();

      // Add scroll listener for pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // Load more users when scrolled to the bottom
          userProvider.loadMoreUsers(
            searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
            roleFilter: _roleFilter,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform delete operation
              final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
              userProvider.deleteUser(user.id);
              Navigator.of(context).pop();
            },
            child: Text('Xóa'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Show dialog to update user role
  void _showUpdateRoleDialog(BuildContext context, User user) {
    String newRole = user.role;
    final roleOptions = ['customer', 'admin'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật quyền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Người dùng: ${user.fullName}'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: newRole,
              decoration: InputDecoration(
                labelText: 'Quyền',
                border: OutlineInputBorder(),
              ),
              items: roleOptions.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleText(role)),
                );
              }).toList(),
              onChanged: (value) {
                newRole = value!;
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
              if (newRole != user.role) {
                final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
                userProvider.updateUserRole(user.id, newRole);
              }
              Navigator.of(context).pop();
            },
            child: Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit user details
  void _showEditUserDialog(BuildContext context, User user) {
    final _formKey = GlobalKey<FormState>();
    final _fullNameController = TextEditingController(text: user.fullName);
    final _emailController = TextEditingController(text: user.email);
    final _addressController = TextEditingController(text: user.shippingAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa thông tin người dùng'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email (readonly because it's used for login)
                TextFormField(
                  controller: _emailController,
                  readOnly: true, // Email không thể sửa
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
                SizedBox(height: 16),

                // Phone
                SizedBox(height: 16),

                // Shipping Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ giao hàng',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedUser = User(
                  id: user.id,
                  fullName: _fullNameController.text.trim(),
                  email: user.email, // Giữ nguyên email
                  role: user.role, // Giữ nguyên role
                  shippingAddress: _addressController.text.trim(),
                );

                final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
                userProvider.updateUser(updatedUser);
                Navigator.of(context).pop();
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Get formatted role text
  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'customer':
        return 'Khách hàng';
      default:
        return role;
    }
  }

  // Apply filters and refresh users
  void _applyFilters() {
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
    userProvider.fetchUsers(
      searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      roleFilter: _roleFilter,
    );
  }

  // Reset filters
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _roleFilter = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý người dùng'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên, email...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // Reset search
                    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
                    userProvider.fetchUsers(roleFilter: _roleFilter);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                // Perform search
                final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
                userProvider.fetchUsers(
                  searchQuery: value.isNotEmpty ? value : null,
                  roleFilter: _roleFilter,
                );
              },
            ),
          ),

          // Role filter chips

          // User List
          Expanded(
            child: Consumer<AdminUserProvider>(
              builder: (context, userProvider, child) {
                // Show loading indicator while fetching users
                if (userProvider.isLoading && userProvider.users.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                // Show message if no users
                if (userProvider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng nào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_roleFilter != null || _searchController.text.isNotEmpty)
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Xóa bộ lọc'),
                            onPressed: _resetFilters,
                          ),
                      ],
                    ),
                  );
                }

                // User List
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: userProvider.users.length +
                      (userProvider.hasMoreUsers ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == userProvider.users.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final user = userProvider.users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(user.role),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _getRoleText(user.role),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditUserDialog(context, user);
                              },
                            ),
                            // Role Button
                            // Delete Button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, user);
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
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

  // Get avatar color based on role
  Color _getAvatarColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'customer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get role color
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'customer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}