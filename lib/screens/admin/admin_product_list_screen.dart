import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_product_model.dart';
import '../../providers/admin_product_provider.dart';
import 'admin_product_management_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  @override
  _AdminProductListScreenState createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch initial products when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<AdminProductProvider>(context, listen: false);
      productProvider.fetchProducts();

      // Add scroll listener for pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // Load more products when scrolled to the bottom
          productProvider.fetchProducts();
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
  void _showDeleteConfirmation(BuildContext context, AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform delete operation
              final productProvider = Provider.of<AdminProductProvider>(context, listen: false);
              productProvider.deleteProduct(product.id!);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to add new product screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminProductManagementScreen(),
                ),
              );
            },
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
                    // Perform search or reset
                    Provider.of<AdminProductProvider>(context, listen: false)
                        .fetchProducts();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                // Perform search
                Provider.of<AdminProductProvider>(context, listen: false)
                    .fetchProducts(searchQuery: value);
              },
            ),
          ),

          // Product List
          Expanded(
            child: Consumer<AdminProductProvider>(
              builder: (context, productProvider, child) {
                // Show loading indicator while fetching products
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                // Show message if no products
                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  );
                }

                // Product List
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: productProvider.products.length +
                      (productProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == productProvider.products.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final product = productProvider.products[index];
                    return ProductListItem(
                      product: product,
                      onEdit: () {
                        // Navigate to edit product screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminProductManagementScreen(
                              existingProduct: product,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _showDeleteConfirmation(context, product),
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
}

// Product List Item Widget
class ProductListItem extends StatelessWidget {
  final AdminProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListItem({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        // Product Image
        leading: product.imageUrls.isNotEmpty
            ? Image.network(
          product.imageUrls.first,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        )
            : Icon(Icons.image, size: 80),

        // Product Details
        title: Text(
          product.name,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand: ${product.brand}'),
            Text('Category: ${product.category}'),
            Text('Price: ${product.price.toStringAsFixed(0)}đ'),
          ],
        ),

        // Action Buttons
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Button
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            // Delete Button
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}