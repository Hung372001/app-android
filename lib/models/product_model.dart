class ProductVariant {
  final String id;
  final String name;
  final double price;
  final int stock;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String category;
  final String description;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.variants,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      variants: (json['variants'] as List<dynamic>?)
          ?.map((variant) => ProductVariant.fromJson(variant))
          .toList() ??
          [],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
      'variants': variants.map((variant) => variant.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  // Enum for product categories
  static final List<String> categories = [
    'Laptops',
    'Monitors',
    'Hard Drives',
    'Processors',
    'Graphics Cards',
    'Motherboards',
    'RAM',
    'Power Supplies',
    'Computer Cases',
  ];
}

// Product Review Model
class ProductReview {
  final String id;
  final String userId;
  final String username;
  final String comment;
  final int rating;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.userId,
    required this.username,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Anonymous',
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}