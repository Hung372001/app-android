// Widget ProductCard với nút thêm vào giỏ hàng đã được sửa lại
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/routes.dart';

final fomater = NumberFormat('#,##0', 'vi_VN');
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
    // Calculate fixed heights to prevent overflow
    final double cardWidth = (MediaQuery.of(context).size.width - 32) / 2; // Assuming 2 cards per row with 16px padding
    final double imageHeight = cardWidth; // Square image with aspectRatio: 1
    final double detailsHeight = 100; // Fixed height for details section

    return SizedBox(
      // Set fixed height for the entire card to prevent overflow
      height: imageHeight + detailsHeight,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Product Image - Có thể nhấn vào để xem chi tiết
            InkWell(
              onTap: onTap,
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
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

            // Product Details - Fixed height
            SizedBox(
              height: detailsHeight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name - Có thể nhấn vào để xem chi tiết
                    InkWell(
                      onTap: onTap,
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
                    SizedBox(height: 6),

                    // Price and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          '${fomater.format(product.price)}đ',
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

                    // Add to Cart Button - Uncomment if you need it
                    // SizedBox(height: 8),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     icon: Icon(Icons.shopping_cart, size: 16),
                    //     label: Text('Add to Cart', style: TextStyle(fontSize: 12)),
                    //     style: ElevatedButton.styleFrom(
                    //       padding: EdgeInsets.symmetric(vertical: 8),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //     onPressed: () {
                    //       _addToCart(context);
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm thêm sản phẩm vào giỏ hàng
  void _addToCart(BuildContext context) {
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
}