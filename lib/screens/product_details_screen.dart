import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_review_item.dart';

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
                      Text(
                        product.brand,
                        style: Theme.of(context).textTheme.headlineSmall,
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
                        DropdownButton<ProductVariant>(
                          value: _selectedVariant,
                          items: product.variants.map((variant) {
                            return DropdownMenuItem(
                              value: variant,
                              child: Text(variant.name),
                            );
                          }).toList(),
                          onChanged: (variant) {
                            setState(() {
                              _selectedVariant = variant!;
                            });
                          },
                        ),

                      // Description
                      Text(
                        'Description:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      // Quantity Selector and Add to Cart
                      Row(
                        children: [
                          Text('Quantity:'),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                          ),
                          Text('$_quantity'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                          ),
                          Spacer(),
                          ElevatedButton(
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
                            child: Text('Add to Cart'),
                          ),
                        ],
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
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () => _showReviewDialog(product),
                            child: Text('Write a Review'),
                          ),
                        ],
                      ),

                      // Reviews List
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          final reviews = productProvider.productReviews;

                          if (reviews.isEmpty) {
                            return Center(
                              child: Text('No reviews yet'),
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
            ],
          );
        },
      ),
    );
  }
}