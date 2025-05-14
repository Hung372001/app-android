import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthProvider _authProvider;

  ProductProvider(this._authProvider);

  // Product Lists
  List<Product> _products = [];
  List<Product> get products => _products;

  // Separate product lists for different categories
  Map<String, List<Product>> _categorizedProducts = {};

  // Pagination and Loading State
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreProducts = true;

  // Filtering and Sorting State
  ProductFilterOptions? _currentFilters;
  String _currentSortOption = ProductSortOptions.relevance;
  String? _currentSearchQuery;

  // Getters for state
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  bool get hasMoreProducts => _hasMoreProducts;
  ProductFilterOptions? get currentFilters => _currentFilters;
  String get currentSortOption => _currentSortOption;
  String? get currentSearchQuery => _currentSearchQuery;

  // Method to get products by category
  List<Product> getProductsByCategory(String category) {
    return _categorizedProducts[category] ?? [];
  }

  // Fetch products with comprehensive error handling
  Future<void> fetchProducts({
    ProductFilterOptions? filters,
    String sortBy = ProductSortOptions.relevance,
    String? searchQuery,
    int limit = 20,
  }) async {
    // Set loading state
    _isLoading = true;
    _currentPage = 1;
    _currentFilters = filters;
    _currentSortOption = sortBy;
    _currentSearchQuery = searchQuery;
    notifyListeners();

    try {
      final fetchedProducts = await _productService.fetchProducts(
        page: _currentPage,
        filters: filters,
        sortBy: sortBy,
        searchQuery: searchQuery,
        limit: limit,
      );

      // If filters contain a category, store in categorized products
      if (filters?.category != null) {
        _categorizedProducts[filters!.category!] = fetchedProducts;
      } else {
        // If no specific category, update main products list
        _products = fetchedProducts;
      }

      _hasMoreProducts = fetchedProducts.length == limit;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
      _isLoading = false;

      // Clear products for the category if fetch fails
      if (_currentFilters?.category != null) {
        _categorizedProducts[_currentFilters!.category!] = [];
      } else {
        _products = [];
      }

      _hasMoreProducts = false;
      notifyListeners();
    }
  }

  // Load More Products
  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMoreProducts) return;

    _currentPage++;
    _isLoading = true;
    notifyListeners();

    try {
      final newProducts = await _productService.fetchProducts(
        page: _currentPage,
        filters: _currentFilters,
        sortBy: _currentSortOption,
        searchQuery: _currentSearchQuery,
      );

      // Add new products to existing list or category
      if (_currentFilters?.category != null) {
        final categoryKey = _currentFilters!.category!;
        _categorizedProducts[categoryKey]?.addAll(newProducts);
      } else {
        _products.addAll(newProducts);
      }

      _hasMoreProducts = newProducts.length == 20; // Assuming 20 items per page
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading more products: $e');
      _currentPage--;
      _isLoading = false;
      _hasMoreProducts = false;
      notifyListeners();
    }
  }

  // Fetch Product Details
  Future<void> fetchProductDetails(String productId) async {
    _isLoading = true;
    _selectedProduct = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.fetchProductDetails(productId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching product details: $e');
      _isLoading = false;
      _selectedProduct = null;
      notifyListeners();
    }
  }

  // Product Reviews
  List<ProductReview> _productReviews = [];
  List<ProductReview> get productReviews => _productReviews;
  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  // Fetch Product Reviews
  Future<void> fetchProductReviews(String productId) async {
    try {
      _productReviews = await _productService.fetchProductReviews(productId);
      notifyListeners();
    } catch (e) {
      print('Error fetching product reviews: $e');
      _productReviews = [];
      notifyListeners();
    }
  }

  // Add Product Review
  Future<void> addProductReview({
    required String productId,
    required String comment,
    required int rating,
  }) async {
    // Ensure user is logged in
    final currentUser = _authProvider.currentUser;
    if (currentUser == null) {
      print('User must be logged in to add a review');
      return;
    }

    try {
      final newReview = await _productService.addProductReview(
        productId: productId,
        userId: currentUser.id,
        comment: comment,
        rating: rating,
      );

      if (newReview != null) {
        _productReviews.insert(0, newReview);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding product review: $e');
    }
  }

  // Clear method for categories
  void clearCategorizedProducts() {
    _categorizedProducts.clear();
    notifyListeners();
  }
}