// admin_product_provider.dart (updated)
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/admin_product_model.dart';
import '../services/admin_product_service.dart';
import '../providers/auth_provider.dart';

class AdminProductProvider with ChangeNotifier {
  final AdminProductService _productService = AdminProductService();
  final AuthProvider _authProvider;

  AdminProductProvider(this._authProvider);

  // Product management state
  List<AdminProduct> _products = [];
  List<AdminProduct> get products => _products;

  AdminProduct? _selectedProduct;
  AdminProduct? get selectedProduct => _selectedProduct;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fetch Products
  Future<void> fetchProducts({
    int page = 1,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.fetchProducts(
        page: page,
        searchQuery: searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch products';
      notifyListeners();
    }
  }

  // Get product by ID
  Future<AdminProduct?> getProductById(String id) async {
    try {
      // First try to find it in the local cache
      AdminProduct? product = _products.firstWhere(
            (p) => p.id == id,
        orElse: () => null as AdminProduct,
      );

      // If not found in cache, fetch from API
      if (product == null) {
        product = await _productService.getProductById(id);
      }

      return product;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Select Product for Editing
  void selectProduct(AdminProduct product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Create Product with images
  Future<bool> createProduct(AdminProduct product, List<File> imageFiles) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdProduct = await _productService.createProduct(product, imageFiles);

      if (createdProduct != null) {
        _products.insert(0, createdProduct);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to create product';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error creating product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update Product
  Future<bool> updateProduct(AdminProduct product, [List<File>? newImages]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProduct = await _productService.updateProduct(product, newImages);

      if (updatedProduct != null) {
        // Find and replace the product in the list
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to update product';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Delete Product
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _productService.deleteProduct(productId);

      if (success) {
        // Remove product from the list
        _products.removeWhere((product) => product.id == productId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to delete product';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error deleting product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}