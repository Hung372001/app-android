import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/coupon_model.dart';
import '../../providers/admin_coupon_provider.dart';

class AdminCouponManagementScreen extends StatefulWidget {
  @override
  _AdminCouponManagementScreenState createState() => _AdminCouponManagementScreenState();
}

class _AdminCouponManagementScreenState extends State<AdminCouponManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch initial coupons when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final couponProvider = Provider.of<AdminCouponProvider>(context, listen: false);
      couponProvider.fetchCoupons();

      // Add scroll listener for pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // Load more coupons when scrolled to the bottom
          couponProvider.loadMoreCoupons();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Coupon'),
        content: Text('Are you sure you want to delete the coupon "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform delete operation
              final couponProvider = Provider.of<AdminCouponProvider>(context, listen: false);
              couponProvider.deleteCoupon(coupon.id!);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddEditCouponDialog({Coupon? existingCoupon}) {
    final _formKey = GlobalKey<FormState>();

    // Form controllers
    final _codeController = TextEditingController(text: existingCoupon?.code ?? '');
    final _discountController = TextEditingController(
        text: existingCoupon?.discountPercent.toString() ?? '');
    final _minOrderController = TextEditingController(
        text: existingCoupon?.minOrderValue.toString() ?? '0');
    final _maxDiscountController = TextEditingController(
        text: existingCoupon?.maxDiscountValue.toString() ?? '0');

    DateTime _startDate = existingCoupon?.startDate ?? DateTime.now();
    DateTime _endDate = existingCoupon?.endDate ?? DateTime.now().add(Duration(days: 30));

    bool _isActive = existingCoupon?.isActive ?? true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(existingCoupon == null ? 'Add New Coupon' : 'Edit Coupon'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coupon Code
                        TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(labelText: 'Coupon Code'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter coupon code';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Discount Percent
                        TextFormField(
                          controller: _discountController,
                          decoration: InputDecoration(labelText: 'Discount Percent (%)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter discount percent';
                            }
                            final discount = double.tryParse(value);
                            if (discount == null || discount <= 0 || discount > 100) {
                              return 'Discount must be between 1-100%';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Min Order Value
                        TextFormField(
                          controller: _minOrderController,
                          decoration: InputDecoration(labelText: 'Min Order Value (0 for no min)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter minimum order value';
                            }
                            final minValue = double.tryParse(value);
                            if (minValue == null || minValue < 0) {
                              return 'Min value cannot be negative';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Max Discount Value
                        TextFormField(
                          controller: _maxDiscountController,
                          decoration: InputDecoration(labelText: 'Max Discount Value (0 for no max)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum discount value';
                            }
                            final maxValue = double.tryParse(value);
                            if (maxValue == null || maxValue < 0) {
                              return 'Max value cannot be negative';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Date Range
                        Row(
                          children: [
                            Text('Valid Period: '),
                            Expanded(
                              child: Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Date Picker Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                                  lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              child: Text('Start Date'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              child: Text('End Date'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Active Status
                        SwitchListTile(
                          title: Text('Is Active'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process form data
                        final couponProvider = Provider.of<AdminCouponProvider>(context, listen: false);

                        final coupon = Coupon(
                          id: existingCoupon?.id,
                          code: _codeController.text,
                          discountPercent: double.parse(_discountController.text),
                          minOrderValue: double.parse(_minOrderController.text),
                          maxDiscountValue: double.parse(_maxDiscountController.text),
                          startDate: _startDate,
                          endDate: _endDate,
                          isActive: _isActive,
                          usageCount: existingCoupon?.usageCount ?? 0,
                        );

                        if (existingCoupon == null) {
                          // Create new coupon
                          couponProvider.createCoupon(coupon);
                        } else {
                          // Update existing coupon
                          couponProvider.updateCoupon(coupon);
                        }

                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(existingCoupon == null ? 'Add' : 'Update'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coupon Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddEditCouponDialog();
            },
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
                hintText: 'Search coupons...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // Reset search
                    final couponProvider = Provider.of<AdminCouponProvider>(context, listen: false);
                    couponProvider.fetchCoupons();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                // Perform search
                if (value.isNotEmpty) {
                  final couponProvider = Provider.of<AdminCouponProvider>(context, listen: false);
                  couponProvider.fetchCoupons(searchQuery: value);
                }
              },
            ),
          ),

          // Coupon List
          Expanded(
            child: Consumer<AdminCouponProvider>(
              builder: (context, couponProvider, child) {
                // Show loading indicator while fetching coupons
                if (couponProvider.isLoading && couponProvider.coupons.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                // Show message if no coupons
                if (couponProvider.coupons.isEmpty) {
                  return Center(
                    child: Text(
                      'No coupons found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  );
                }

                // Coupon List
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: couponProvider.coupons.length +
                      (couponProvider.hasMoreCoupons ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == couponProvider.coupons.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final coupon = couponProvider.coupons[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              coupon.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: coupon.isActive ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                coupon.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('${coupon.discountPercent}% off'),
                            if (coupon.minOrderValue > 0)
                              Text('Min order: ${coupon.minOrderValue.toStringAsFixed(0)}đ'),
                            if (coupon.maxDiscountValue > 0)
                              Text('Max discount: ${coupon.maxDiscountValue.toStringAsFixed(0)}đ'),
                            Text('Valid: ${coupon.startDate.day}/${coupon.startDate.month}/${coupon.startDate.year} - ${coupon.endDate.day}/${coupon.endDate.month}/${coupon.endDate.year}'),
                            Text('Used ${coupon.usageCount} times'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showAddEditCouponDialog(existingCoupon: coupon);
                              },
                            ),
                            // Delete Button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, coupon);
                              },
                            ),
                          ],
                        ),
                      ),
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
}