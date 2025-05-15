import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart'; // Import để sử dụng danh sách danh mục
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import '../screens/category_product_screen.dart'; // Import màn hình hiển thị sản phẩm theo danh mục

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('E-Commerce Store'),
        actions: [
          // Giỏ hàng
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, Routes.cart);
            },
          ),
          // Hồ sơ người dùng
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
          // Tiêu đề danh mục
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh mục sản phẩm',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.productCatalog);
                  },
                  child: Text('Xem tất cả'),
                ),
              ],
            ),
          ),

          // Danh sách danh mục sản phẩm
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: Product.categories.length,
              itemBuilder: (context, index) {
                final category = Product.categories[index];
                return _buildCategoryCard(
                  context,
                  category,
                  _getCategoryIcon(category),
                      () {
                    // Điều hướng đến màn hình danh mục sản phẩm
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductScreen(category: category),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Hàm để lấy icon phù hợp cho từng danh mục
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Laptops':
        return Icons.laptop;
      case 'Monitors':
        return Icons.desktop_windows;
      case 'Hard Drives':
        return Icons.storage;
      case 'Processors':
        return Icons.memory;
      case 'Graphics Cards':
        return Icons.videogame_asset;
      case 'Motherboards':
        return Icons.developer_board;
      case 'RAM':
        return Icons.memory;
      case 'Power Supplies':
        return Icons.power;
      case 'Computer Cases':
        return Icons.computer;
      default:
        return Icons.devices_other;
    }
  }
}