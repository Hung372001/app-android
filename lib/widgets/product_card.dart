import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

final format = NumberFormat.simpleCurrency(locale: 'vi_VN');
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define fixed card height to prevent overflow
    return SizedBox(
      // Set explicit height for the entire card
      height: 280, // Adjust this value based on your design needs
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero, // Remove default card margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum vertical space
            children: [
              // Product Image - Fixed height using SizedBox instead of AspectRatio
              SizedBox(
                height: 150, // Fixed height for image
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.network(
                    product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : 'https://via.placeholder.com/150',
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
                      return Image.network(
                        'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),

              // Product Details - with constrained height
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Use minimum space needed
                    children: [
                      // Product Name - Reduce text size
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14, // Smaller font size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4), // Smaller spacing

                      // Product Brand - Reduce text size
                      Text(
                        product.brand,
                        style: TextStyle(
                          fontSize: 12, // Smaller font size
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4), // Smaller spacing

                      // Price and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price - Reduce text size
                          Text(
                            '${format.format( product.price)}',
                            style: TextStyle(
                              fontSize: 14, // Smaller font size
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),

                          // Rating
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Add to Cart Button section is commented out in original code
                      // SizedBox(height: 8),
                      // Add to Cart Button code...
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}