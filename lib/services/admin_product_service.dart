// admin_product_service.dart (updated)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/admin_product_model.dart';
import '../utils/constants.dart';

class AdminProductService {
  final String baseUrl = '${AppConstants.baseUrl}/admin/products';

  // Fetch all products
  Future<List<AdminProduct>> fetchProducts({
    int page = 1,
    int limit = 20,
    String? searchQuery,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (searchQuery != null) 'search': searchQuery,
      };

      final response = await http.get(
        Uri.parse(baseUrl).replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> productList = json.decode(response.body)['products'];
        return productList.map((product) => AdminProduct.fromJson(product)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Create a new product with images
  Future<AdminProduct?> createProduct(AdminProduct product, List<File> imageFiles) async {
    try {
      // Tạo multipart request để tải lên cả dữ liệu sản phẩm và hình ảnh
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      // Thêm thông tin sản phẩm
      request.fields['name'] = product.name;
      request.fields['brand'] = product.brand;
      request.fields['category'] = product.category;
      request.fields['price'] = product.price.toString();
      request.fields['description'] = product.description;

      // Thêm thông tin variants
      if (product.variants.isNotEmpty) {
        request.fields['variants'] = jsonEncode(
            product.variants.map((v) => v.toJson()).toList()
        );
      }

      // Thêm các file ảnh
      for (var file in imageFiles) {
        request.files.add(
              await http.MultipartFile.fromPath('images', file.path)
        );
      }

      // Gửi request
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return AdminProduct.fromJson(responseData['product']);
      }

      print('Failed to create product: ${response.body}');
      return null;
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  // Update an existing product
  Future<AdminProduct?> updateProduct(AdminProduct product, List<File>? newImages) async {
    if (product.id == null) {
      throw Exception('Product ID is required for update');
    }

    try {
      if (newImages != null && newImages.isNotEmpty) {
        // Nếu có hình ảnh mới, sử dụng multipart request
        var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/${product.id}'));

        // Thêm thông tin sản phẩm
        request.fields['name'] = product.name;
        request.fields['brand'] = product.brand;
        request.fields['category'] = product.category;
        request.fields['price'] = product.price.toString();
        request.fields['description'] = product.description;

        // Thêm danh sách imageUrls hiện có
        if (product.imageUrls.isNotEmpty) {
          request.fields['imageUrls'] = jsonEncode(product.imageUrls);
        }

        // Thêm thông tin variants
        if (product.variants.isNotEmpty) {
          request.fields['variants'] = jsonEncode(
              product.variants.map((v) => v.toJson()).toList()
          );
        }

        // Thêm các file ảnh mới
        for (var file in newImages) {
          request.files.add(
              await http.MultipartFile.fromPath('images', file.path)
          );
        }

        // Gửi request
        final streamResponse = await request.send();
        final response = await http.Response.fromStream(streamResponse);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return AdminProduct.fromJson(responseData['product']);
        }
      } else {
        // Nếu không có hình ảnh mới, sử dụng request JSON thông thường
        final response = await http.put(
          Uri.parse('$baseUrl/${product.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );

        if (response.statusCode == 200) {
          return AdminProduct.fromJson(json.decode(response.body)['product']);
        }
      }

      return null;
    } catch (e) {
      print('Error updating product: $e');
      return null;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Get product by ID
  Future<AdminProduct?> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return AdminProduct.fromJson(json.decode(response.body)['product']);
      }
      return null;
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }
}