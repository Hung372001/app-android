  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../models/product_model.dart';
  import '../utils/constants.dart';

  class ProductFilterOptions {
    final String? category;
    final double? minPrice;
    final double? maxPrice;
    final double? minRating;

    ProductFilterOptions({
      this.category,
      this.minPrice,
      this.maxPrice,
      this.minRating,
    });
  }

  class ProductSortOptions {
    static const String nameAscending = 'name_asc';
    static const String nameDescending = 'name_desc';
    static const String priceAscending = 'price_asc';
    static const String priceDescending = 'price_desc';
    static const String relevance = 'relevance';
  }

  class ProductService {
    final String baseUrl = '${AppConstants.baseUrl}/products';

    // Fetch products with pagination and filtering
    Future<List<Product>> fetchProducts({
      int limit = 20,
      ProductFilterOptions? filters,
      String sortBy = ProductSortOptions.relevance,
      String? searchQuery,
    }) async {
      try {
        final queryParams = {
          if (searchQuery != null) 'search': searchQuery,
          if (filters?.category != null) 'category': filters!.category,
          if (filters?.minPrice != null) 'minPrice': filters!.minPrice.toString(),
          if (filters?.maxPrice != null) 'maxPrice': filters!.maxPrice.toString(),
          if (filters?.minRating != null) 'minRating': filters!.minRating.toString(),
        };

        final response = await http.get(
          Uri.parse(baseUrl).replace(queryParameters: queryParams),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> productList = json.decode(response.body)['products'];
          print('Fetched ${productList} products');
          return productList.map((product) => Product.fromJson(product)).toList();
        }
        return [];
      } catch (e) {
        print('Error fetching products: $e');
        return [];
      }
    }

    // Fetch single product details
    Future<Product?> fetchProductDetails(String productId) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/$productId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {

          print('Fetched product details: ${response.body}');
          return Product.fromJson(json.decode(response.body)['product']);

        }
        return null;
      } catch (e) {
        print('Error fetching product details: $e');
        return null;
      }
    }

    // Fetch product reviews
    Future<List<ProductReview>> fetchProductReviews(String productId) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/$productId/reviews'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> reviewList = json.decode(response.body)['reviews'];
          return reviewList.map((review) => ProductReview.fromJson(review)).toList();
        }
        return [];
      } catch (e) {
        print('Error fetching product reviews: $e');
        return [];
      }
    }

    // Add product review
    Future<ProductReview?> addProductReview({
      required String productId,
      required String userId,
      required String comment,
      required int rating,
    }) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/$productId/reviews'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': userId,
            'comment': comment,
            'rating': rating,
          }),
        );

        if (response.statusCode == 201) {
          return ProductReview.fromJson(json.decode(response.body));
        }
        return null;
      } catch (e) {
        print('Error adding product review: $e');
        return null;
      }
    }
  }