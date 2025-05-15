import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/routes.dart';

class ProductCatalogScreen extends StatefulWidget {
  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSortOption = ProductSortOptions.relevance;
  RangeValues _priceRange = RangeValues(0, 100000);
  bool _isFirstLoad = true;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    // Load initial products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      _updateCartCount();

      // Add scroll listener for pagination
      _scrollController.addListener(_onScroll);
    });
  }

  // Cập nhật số lượng sản phẩm trong giỏ hàng
  void _updateCartCount() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    setState(() {
      _cartItemCount = cartProvider.totalItems;
    });

    // Đăng ký lắng nghe sự thay đổi của giỏ hàng
    cartProvider.addListener(() {
      setState(() {
        _cartItemCount = cartProvider.totalItems;
      });
    });
  }

  // Phương thức tải sản phẩm ban đầu
  Future<void> _loadProducts() async {
    try {
      await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      setState(() {
        _isFirstLoad = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadProducts,
          ),
        ),
      );
      setState(() {
        _isFirstLoad = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Trigger load more
      Provider.of<ProductProvider>(context, listen: false).loadMoreProducts();
    }
  }

  void _applyFilters() {
    setState(() {
      _isFirstLoad = true;
    });

    final filters = ProductFilterOptions(
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
    );

    Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      filters: filters,
      sortBy: _selectedSortOption,
      searchQuery: _searchController.text.trim(),
    ).then((_) {
      setState(() {
        _isFirstLoad = false;
      });
    });
  }

  // Lọc ra sản phẩm hợp lệ (không phải sản phẩm test)
  List<Product> _filterValidProducts(List<Product> products) {
    // Lọc các sản phẩm có tên bắt đầu bằng "test" hoặc có giá bằng 0
    return products.where((product) {
      // Kiểm tra sản phẩm hợp lệ:
      // - Tên không bắt đầu bằng "test" (không phân biệt hoa thường)
      // - Giá phải lớn hơn 0
      // - Có ít nhất 1 ảnh
      return !product.name.toLowerCase().startsWith('test') &&
          product.price > 0 &&
          product.imageUrls.isNotEmpty;
    }).toList();
  }

  // Thêm sản phẩm vào giỏ hàng
  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Lấy variant đầu tiên hoặc tạo variant mặc định nếu không có
    final variant = product.variants.isNotEmpty
        ? product.variants.first
        : ProductVariant(
        id: '',
        name: 'Default',
        price: product.price,
        stock: 0
    );

    // Thêm sản phẩm vào giỏ hàng
    cartProvider.addToCart(
      product: product,
      variant: variant,
      quantity: 1,
    );

    // Hiển thị thông báo đã thêm vào giỏ hàng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            // Chuyển đến trang giỏ hàng
            Navigator.pushNamed(context, Routes.cart);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Catalog'),
        actions: [
          // Filter Icon
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),

          // Cart Icon với badge hiển thị số lượng
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.cart);
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Selected Filters Chips
          if (_selectedCategory.isNotEmpty || _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory.isNotEmpty)
                    Chip(
                      label: Text('Category: $_selectedCategory'),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = '';
                        });
                        _applyFilters();
                      },
                    ),
                  if (_searchController.text.isNotEmpty)
                    Chip(
                      label: Text('Search: ${_searchController.text}'),
                      onDeleted: () {
                        setState(() {
                          _searchController.clear();
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                // Hiển thị trạng thái đang tải lần đầu
                if (_isFirstLoad) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading products...'),
                      ],
                    ),
                  );
                }

                // Lọc các sản phẩm hợp lệ (không phải sản phẩm test)
                final validProducts = _filterValidProducts(productProvider.products);

                // Hiển thị trạng thái đang tải và chưa có sản phẩm
                if (productProvider.isLoading && validProducts.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                // Hiển thị thông báo khi không có sản phẩm
                if (validProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter criteria',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = '';
                              _searchController.clear();
                              _selectedSortOption = ProductSortOptions.relevance;
                              _priceRange = RangeValues(0, 100000);
                            });
                            _loadProducts();
                          },
                          child: Text('Reset Filters'),
                        ),
                      ],
                    ),
                  );
                }

                // Hiển thị danh sách sản phẩm
                return RefreshIndicator(
                  onRefresh: () async {
                    await Provider.of<ProductProvider>(context, listen: false).fetchProducts(
                      filters: _selectedCategory.isEmpty
                          ? null
                          : ProductFilterOptions(category: _selectedCategory),
                      sortBy: _selectedSortOption,
                      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
                    );
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65, // Điều chỉnh để phù hợp với nút Add to Cart
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: validProducts.length +
                        (productProvider.hasMoreProducts && !productProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loading indicator at the end
                      if (index == validProducts.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Hiển thị sản phẩm
                      final product = validProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating button để kéo lên đầu
      floatingActionButton: _scrollController.hasClients && _scrollController.offset > 300
          ? FloatingActionButton(
        mini: true,
        child: Icon(Icons.arrow_upward),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      )
          : null,
    );
  }

  // Tạo ProductCard tích hợp với màn hình này
  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image - Có thể nhấn vào để xem chi tiết
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                  context,
                  Routes.productDetails,
                  arguments: product.id
              );
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                  product.imageUrls.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Hiển thị hình ảnh thay thế khi không tải được
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name - Có thể nhấn vào để xem chi tiết
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                        context,
                        Routes.productDetails,
                        arguments: product.id
                    );
                  },
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4),

                // Product Brand
                Text(
                  product.brand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                // Price and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      '${product.price.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    // Rating
                    if (product.rating > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),

                // Add to Cart Button
                SizedBox(height: 8),

              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 8),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Category Filter
                      Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Product.categories.map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : '';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      // Price Range Slider
                      Text(
                        'Price Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_priceRange.start.toStringAsFixed(0)}đ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_priceRange.end.toStringAsFixed(0)}đ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 100000,
                        divisions: 100,
                        labels: RangeLabels(
                          '${_priceRange.start.toStringAsFixed(0)}đ',
                          '${_priceRange.end.toStringAsFixed(0)}đ',
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Sorting Options
                      Text(
                        'Sort By',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildSortOption(
                              setState,
                              ProductSortOptions.relevance,
                              'Relevance',
                              Icons.trending_up,
                            ),
                            Divider(height: 1),
                            _buildSortOption(
                              setState,
                              ProductSortOptions.nameAscending,
                              'Name (A-Z)',
                              Icons.sort_by_alpha,
                            ),
                            Divider(height: 1),
                            _buildSortOption(
                              setState,
                              ProductSortOptions.nameDescending,
                              'Name (Z-A)',
                              Icons.sort_by_alpha,
                            ),
                            Divider(height: 1),
                            _buildSortOption(
                              setState,
                              ProductSortOptions.priceAscending,
                              'Price (Low to High)',
                              Icons.arrow_upward,
                            ),
                            Divider(height: 1),
                            _buildSortOption(
                              setState,
                              ProductSortOptions.priceDescending,
                              'Price (High to Low)',
                              Icons.arrow_downward,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Apply and Reset Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: Text('Reset'),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = '';
                          _priceRange = RangeValues(0, 100000);
                          _selectedSortOption = ProductSortOptions.relevance;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      child: Text('Apply'),
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget để xây dựng tùy chọn sắp xếp
  Widget _buildSortOption(
      StateSetter setState,
      String value,
      String label,
      IconData icon,
      ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSortOption = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _selectedSortOption == value ? Colors.blue : Colors.grey),
            SizedBox(width: 16),
            Text(label),
            Spacer(),
            if (_selectedSortOption == value)
              Icon(Icons.check, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}