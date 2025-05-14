import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/routes.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Kiểm tra đăng nhập
    if (authProvider.currentUser == null) {
      return _buildLoginPrompt(context);
    }

    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 10),
                    Text('Name: ${user.fullName}'),
                    Text('Email: ${user.email}'),
                    Text('Role: ${user.role}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Nút chức năng
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nút chuyển đến Admin Dashboard (chỉ hiển thị khi là admin)
                if (authProvider.isAdmin)
                  ElevatedButton.icon(
                    icon: Icon(Icons.admin_panel_settings),
                    label: Text('Admin Dashboard'),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.adminDashboard);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                // Các nút khác
                ElevatedButton.icon(
                  icon: Icon(Icons.shopping_basket),
                  label: Text('My Orders'),
                  onPressed: () {
                    // TODO: Chuyển đến màn hình quản lý đơn hàng
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Màn hình yêu cầu đăng nhập
  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Please log in to view your profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Chuyển đến màn hình đăng nhập
                Navigator.pushNamed(context, Routes.login);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  // Logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform logout
              Provider.of<AuthProvider>(context, listen: false).logout();

              // Navigate to login screen and remove all previous routes
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.login,
                      (Route<dynamic> route) => false
              );
            },
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}