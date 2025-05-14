import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/admin_product_model.dart';
import '../../providers/admin_product_provider.dart';

class AdminProductManagementScreen extends StatefulWidget {
  final AdminProduct? existingProduct;

  const AdminProductManagementScreen({Key? key, this.existingProduct}) : super(key: key);

  @override
  _AdminProductManagementScreenState createState() => _AdminProductManagementScreenState();
}

class _AdminProductManagementScreenState extends State<AdminProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  String? _selectedCategory;

  // Variant Controllers
  List<Map<String, TextEditingController>> _variantControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // If editing an existing product
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _nameController = TextEditingController(text: product.name);
      _brandController = TextEditingController(text: product.brand);
      _priceController = TextEditingController(text: product.price.toString());
      _descriptionController = TextEditingController(text: product.description);
      _selectedCategory = product.category;
      _existingImageUrls = product.imageUrls;

      // Initialize variant controllers
      _variantControllers = product.variants.map((variant) {
        return {
          'name': TextEditingController(text: variant.name),
          'price': TextEditingController(text: variant.price.toString()),
          'stock': TextEditingController(text: variant.stock.toString()),
        };
      }).toList();
    } else {
      // New product
      _nameController = TextEditingController();
      _brandController = TextEditingController();
      _priceController = TextEditingController();
      _descriptionController = TextEditingController();

      // Add initial variant
      _addVariantController();
    }
  }

  void _addVariantController() {
    setState(() {
      _variantControllers.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
        'stock': TextEditingController(),
      });
    });
  }

  void _removeVariantController(int index) {
    setState(() {
      _variantControllers[index]['name']?.dispose();
      _variantControllers[index]['price']?.dispose();
      _variantControllers[index]['stock']?.dispose();
      _variantControllers.removeAt(index);
    });
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
    });
  }

  void _submitProduct(AdminProductProvider productProvider) async {
    if (_formKey.currentState!.validate()) {
      // Validate at least one image is selected for new product
      if (widget.existingProduct == null && _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select at least one image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare variants
      final variants = _variantControllers.map((controllers) {
        return AdminProductVariant(
          name: controllers['name']!.text,
          price: double.parse(controllers['price']!.text),
          stock: int.parse(controllers['stock']!.text),
        );
      }).toList();

      // Create product object
      final product = AdminProduct(
        id: widget.existingProduct?.id,
        name: _nameController.text,
        brand: _brandController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        imageUrls: _existingImageUrls,
        variants: variants,
      );

      bool success;
      if (widget.existingProduct == null) {
        // Creating new product with images
        success = await productProvider.createProduct(product, _selectedImages);
      } else {
        // Updating existing product
        success = await productProvider.updateProduct(
            product,
            _selectedImages.isNotEmpty ? _selectedImages : null
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.existingProduct == null
                    ? 'Product created successfully'
                    : 'Product updated successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Failed to save product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();

    _variantControllers.forEach((controllers) {
      controllers['name']?.dispose();
      controllers['price']?.dispose();
      controllers['stock']?.dispose();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingProduct == null
                ? 'Add New Product'
                : 'Edit Product'
        ),
      ),
      body: Consumer<AdminProductProvider>(
        builder: (context, productProvider, child) {
          return productProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Upload
                  _buildImageUploadSection(),

                  // Basic Product Information
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Product Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(labelText: 'Brand'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter brand';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: 'Category'),
                    items: AdminProduct.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Product Variants
                  Text(
                    'Product Variants',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ...List.generate(_variantControllers.length, (index) {
                    return _buildVariantFields(index, productProvider);
                  }),

                  ElevatedButton(
                    onPressed: _addVariantController,
                    child: Text('Add Variant'),
                  ),
                  SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () => _submitProduct(productProvider),
                    child: Text(
                        widget.existingProduct == null
                            ? 'Create Product'
                            : 'Update Product'
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        SizedBox(height: 10),

        if (widget.existingProduct == null)
          Text(
            'At least one image is required',
            style: TextStyle(color: Colors.red),
          ),

        // Existing Images
        if (_existingImageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Image.network(
                        _existingImageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _existingImageUrls.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Selected New Images
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Image.file(
                        _selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Pick Images Button
        ElevatedButton(
          onPressed: _pickImages,
          child: Text('Pick Images'),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVariantFields(int index, AdminProductProvider productProvider) {
    final controllers = _variantControllers[index];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers['name'],
                decoration: InputDecoration(labelText: 'Variant Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter variant name';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controllers['price'],
                decoration: InputDecoration(labelText: 'Variant Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers['stock'],
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid stock';
                  }
                  return null;
                },
              ),
            ),
            // Remove Variant Button (only if more than one variant)
            if (_variantControllers.length > 1)
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeVariantController(index),
              ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }
}