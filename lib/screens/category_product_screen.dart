import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../utils/routes.dart';

class CategoryProductScreen extends StatefulWidget {
  final String category;

  const CategoryProductScreen({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryProductScreenState createState() => _CategoryProductScreenState();
}

class _CategoryProductScreenState extends State<CategoryProductScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải sản phẩm theo danh mục khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryProducts();

      // Thêm listener cho cuộn để tải thêm sản phẩm khi cuộn đến cuối
      _scrollController.addListener(_onScroll);
    });
  }

  // Tải sản phẩm theo danh mục
  void _loadCategoryProducts() {
    final filters = ProductFilterOptions(
      category: widget.category,
    );

    Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      filters: filters,
    );
  }

  // Xử lý sự kiện cuộn
  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      Provider.of<ProductProvider>(context, listen: false).loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Lấy danh sách sản phẩm từ danh mục cụ thể
          final categoryProducts = productProvider.getProductsByCategory(widget.category);

          // Hiển thị loading indicator khi đang tải và chưa có sản phẩm
          if (productProvider.isLoading && categoryProducts.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          // Hiển thị thông báo khi không có sản phẩm
          if (categoryProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có sản phẩm trong danh mục này',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadCategoryProducts,
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          // Hiển thị danh sách sản phẩm
          return RefreshIndicator(
            onRefresh: () async {
              // Làm mới danh sách sản phẩm khi người dùng kéo xuống
              _loadCategoryProducts();
            },
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categoryProducts.length +
                  (productProvider.hasMoreProducts ? 1 : 0), // Thêm 1 vị trí để hiển thị loading indicator
              itemBuilder: (context, index) {
                // Hiển thị loading indicator ở cuối danh sách
                if (index == categoryProducts.length) {
                  return Center(child: CircularProgressIndicator());
                }

                final product = categoryProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Điều hướng đến trang chi tiết sản phẩm
                    Navigator.pushNamed(
                      context,
                      Routes.productDetails,
                      arguments: product.id,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}