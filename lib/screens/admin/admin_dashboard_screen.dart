import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Show logout confirmation
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          // Product Management
          _buildDashboardItem(
            context,
            icon: Icons.inventory,
            label: 'Product Management',
            onTap: () {
              Navigator.pushNamed(context, Routes.adminProductList);
            },
          ),

          // Order Management
          _buildDashboardItem(
            context,
            icon: Icons.shopping_cart,
            label: 'Order Management',
            onTap: () {
              // TODO: Implement Order Management Screen
              Navigator.pushNamed(context, Routes.adminOrderManagement);


            },
          ),

          // User Management
          _buildDashboardItem(
            context,
            icon: Icons.people,
            label: 'User Management',
            onTap: () {
              // TODO: Implement User Management Screen

            },
          ),

          // Coupon Management
          _buildDashboardItem(
            context,
            icon: Icons.discount,
            label: 'Coupon Management',
            onTap: () {
              // TODO: Implement Coupon Management Screen
              Navigator.pushNamed(context, Routes.adminCouponManagement);

            },
          ),

          // Dashboard
          _buildDashboardItem(
            context,
            icon: Icons.dashboard,
            label: 'Sales Dashboard',
            onTap: () {
              // TODO: Implement Sales Dashboard Screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sales Dashboard Coming Soon')),
              );
            },
          ),

          // Customer Support
          _buildDashboardItem(
            context,
            icon: Icons.support_agent,
            label: 'Customer Support',
            onTap: () {
              // TODO: Implement Customer Support Screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Customer Support Coming Soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build dashboard items
  Widget _buildDashboardItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
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