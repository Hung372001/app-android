import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../utils/routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the order from arguments
    final order = ModalRoute.of(context)!.settings.arguments as Order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt hàng thành công'),
        automaticallyImplyLeading: false, // Don't show back button
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success icon and message
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Đơn hàng của bạn đã được đặt thành công!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Cảm ơn bạn đã mua sắm cùng chúng tôi',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Order details card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mã đơn hàng:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '#${order.orderNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ngày đặt:'),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Trạng thái:'),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),

                      // Customer info
                      Text(
                        'Thông tin khách hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(order.customerName),
                      Text(order.customerEmail),
                      Text(order.customerPhone),
                      SizedBox(height: 16),

                      // Shipping address
                      Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(order.shippingAddress),
                      SizedBox(height: 16),

                      // Payment info
                      Text(
                        'Thông tin thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phương thức:'),
                          Text(order.paymentMethod),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Trạng thái:'),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.paymentStatus == 'Paid' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.paymentStatus,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),

                      // Order total
                      Text(
                        'Tổng quan đơn hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Số lượng sản phẩm:'),
                          Text('${order.items.length} sản phẩm'),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính:'),
                          Text('${order.subtotal.toStringAsFixed(0)}đ'),
                        ],
                      ),
                      if (order.discountAmount > 0) ...[
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giảm giá:'),
                            Text(
                              '-${order.discountAmount.toStringAsFixed(0)}đ',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí vận chuyển:'),
                          Text('${order.shippingFee.toStringAsFixed(0)}đ'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng cộng:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${order.total.toStringAsFixed(0)}đ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.shopping_bag),
                    label: Text('Tiếp tục mua sắm'),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.productCatalog,
                            (route) => route.settings.name == Routes.home,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get color based on order status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.indigo;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}