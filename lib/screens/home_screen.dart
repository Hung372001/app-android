import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/routes.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Không yêu cầu login, không sử dụng authProvider.currentUser
    return Scaffold(
      appBar: AppBar(
        title: Text('E-Commerce Store'),
        actions: [
          // Cart Icon
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, Routes.cart);
            },
          ),
          // Profile Icon - Yêu cầu login
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profile);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Danh mục sản phẩm
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _buildCategoryCard(
                    context,
                    'Laptops',
                    Icons.laptop,
                        () {
                      Navigator.pushNamed(
                        context,
                        Routes.productCatalog,
                        arguments: {'category': 'Laptops'},
                      );
                    }
                ),
                _buildCategoryCard(
                    context,
                    'Monitors',
                    Icons.desktop_windows,
                        () {
                      Navigator.pushNamed(
                        context,
                        Routes.productCatalog,
                        arguments: {'category': 'Monitors'},
                      );
                    }
                ),
                _buildCategoryCard(
                    context,
                    'Graphics Cards',
                    Icons.computer,
                        () {
                      Navigator.pushNamed(
                        context,
                        Routes.productCatalog,
                        arguments: {'category': 'Graphics Cards'},
                      );
                    }
                ),
                // Thêm các danh mục khác
              ],
            ),
          ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
            // Đang ở trang chủ
              break;
            case 1:
              Navigator.pushNamed(context, Routes.productCatalog);
              break;
            case 2:
              Navigator.pushNamed(context, Routes.cart);
              break;
          }
        },
      ),
    );
  }

  // Hàm tạo card danh mục sản phẩm
  Widget _buildCategoryCard(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
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
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}