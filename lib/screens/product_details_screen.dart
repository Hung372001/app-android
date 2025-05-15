// Chi tiết sản phẩm có thêm liên kết đến danh mục
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_review_item.dart';
import '../screens/category_product_screen.dart'; // Import màn hình danh mục

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductVariant _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Fetch product details when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.fetchProductDetails(widget.productId);
      productProvider.fetchProductReviews(widget.productId);
    });
  }

  void _showReviewDialog(Product product) {
    final reviewController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              // Review Text Field
              TextField(
                controller: reviewController,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Submit review logic
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                if (authProvider.currentUser != null) {
                  productProvider.addProductReview(
                    productId: product.id,
                    comment: reviewController.text.trim(),
                    rating: rating,
                  );
                  Navigator.pop(context);
                } else {
                  // Show login prompt
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please log in to submit a review'),
                      action: SnackBarAction(
                        label: 'Login',
                        onPressed: () {
                          // Navigate to login screen
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Loading state
          if (productProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Product not found
          final product = productProvider.selectedProduct;
          if (product == null) {
            return Center(child: Text('Product not found'));
          }

          // Initialize selected variant to first variant
          _selectedVariant = product.variants.isNotEmpty
              ? product.variants.first
              : ProductVariant(id: '', name: 'Default', price: product.price, stock: 0);

          return CustomScrollView(
            slivers: [
              // Product Images
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        product.imageUrls[index],
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
                      );
                    },
                  ),
                ),
              ),

              // Product Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name and Brand
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.brand,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),

                          // NEW: Add category chip that links to category page
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductScreen(
                                    category: product.category,
                                  ),
                                ),
                              );
                            },
                            child: Chip(
                              label: Text(product.category),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          ),
                        ],
                      ),

                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                          ),
                        ],
                      ),

                      // Price
                      Text(
                        'Price: ${_selectedVariant.price.toStringAsFixed(0)}đ',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      // Variants Dropdown
                      if (product.variants.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Variants:', style: TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<ProductVariant>(
                                value: _selectedVariant,
                                isExpanded: true,
                                items: product.variants.map((variant) {
                                  return DropdownMenuItem(
                                    value: variant,
                                    child: Text(
                                      '${variant.name} - ${variant.price.toStringAsFixed(0)}đ',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (variant) {
                                  setState(() {
                                    _selectedVariant = variant!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      // Description
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          product.description,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),

                      // Quantity Selector and Add to Cart
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            Text('Quantity:'),
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$_quantity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              icon: Icon(Icons.shopping_cart),
                              label: Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                cartProvider.addToCart(
                                  product: product,
                                  variant: _selectedVariant,
                                  quantity: _quantity,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added to cart'),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      onPressed: () {
                                        // Navigate to cart screen
                                        Navigator.pushNamed(context, '/cart');
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reviews Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer Reviews',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.rate_review),
                            label: Text('Write a Review'),
                            onPressed: () => _showReviewDialog(product),
                          ),
                        ],
                      ),

                      // Reviews List
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          final reviews = productProvider.productReviews;

                          if (reviews.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No reviews yet. Be the first to review this product!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              return ProductReviewItem(review: reviews[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Related Products section could be added here
            ],
          );
        },
      ),
    );
  }
}