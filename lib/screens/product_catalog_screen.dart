import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../utils/routes.dart';

class ProductCatalogScreen extends StatefulWidget {
  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSortOption = ProductSortOptions.relevance;
  RangeValues _priceRange = RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    // Load initial products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();

      // Add scroll listener for pagination
      _scrollController.addListener(_onScroll);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Trigger load more
      Provider.of<ProductProvider>(context, listen: false).loadMoreProducts();
    }
  }

  void _applyFilters() {
    final filters = ProductFilterOptions(
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
    );

    Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      filters: filters,
      sortBy: _selectedSortOption,
      searchQuery: _searchController.text.trim(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Catalog'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                if (productProvider.products.isEmpty) {
                  return Center(child: Text('No products found'));
                }

                return GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: productProvider.products.length +
                      (productProvider.hasMoreProducts ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == productProvider.products.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final product = productProvider.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        // Navigate to product details
                        Navigator.pushNamed(
                            context,
                            Routes.productDetails,
                            arguments: product.id
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter & Sort',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Category Filter
              Text('Category'),
              Wrap(
                spacing: 10,
                children: Product.categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : '';
                      });
                    },
                  );
                }).toList(),
              ),

              // Price Range Slider
              Text('Price Range'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 100000,
                divisions: 100,
                labels: RangeLabels(
                  '${_priceRange.start.toStringAsFixed(0)}đ',
                  '${_priceRange.end.toStringAsFixed(0)}đ',
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
              ),

              // Sorting Options
              Text('Sort By'),
              DropdownButton<String>(
                value: _selectedSortOption,
                items: [
                  DropdownMenuItem(
                    value: ProductSortOptions.relevance,
                    child: Text('Relevance'),
                  ),
                  DropdownMenuItem(
                    value: ProductSortOptions.nameAscending,
                    child: Text('Name (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: ProductSortOptions.nameDescending,
                    child: Text('Name (Z-A)'),
                  ),
                  DropdownMenuItem(
                    value: ProductSortOptions.priceAscending,
                    child: Text('Price (Low to High)'),
                  ),
                  DropdownMenuItem(
                    value: ProductSortOptions.priceDescending,
                    child: Text('Price (High to Low)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSortOption = value ?? ProductSortOptions.relevance;
                  });
                },
              ),

              // Apply Filters Button
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}