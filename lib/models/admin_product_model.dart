class AdminProductVariant {
  String? id;
  String name;
  double price;
  int stock;

  AdminProductVariant({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory AdminProductVariant.fromJson(Map<String, dynamic> json) {
    return AdminProductVariant(
      id: json['id'],
      name: json['name'],
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

class AdminProduct {
  String? id;
  String name;
  String brand;
  String category;
  double price;
  String description;
  List<String> imageUrls;
  List<AdminProductVariant> variants;

  AdminProduct({
    this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.description,
    this.imageUrls = const [],
    this.variants = const [],
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      price: (json['price'] ?? 0.0).toDouble(),
      description: json['description'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      variants: (json['variants'] as List?)
          ?.map((variant) => AdminProductVariant.fromJson(variant))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  // List of predefined categories
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