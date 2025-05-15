class Coupon {
  final String? id;
  final String code;
  final double discountPercent;
  final double minOrderValue;
  final double maxDiscountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int usageCount;

  Coupon({
    this.id,
    required this.code,
    required this.discountPercent,
    this.minOrderValue = 0,
    this.maxDiscountValue = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.usageCount = 0,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      discountPercent: (json['discountPercent'] ?? 0.0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0.0).toDouble(),
      maxDiscountValue: (json['maxDiscountValue'] ?? 0.0).toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(Duration(days: 30)),
      isActive: json['isActive'] ?? true,
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountPercent': discountPercent,
      'minOrderValue': minOrderValue,
      'maxDiscountValue': maxDiscountValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }

  // Helper method to check if the coupon is valid for a given date
  bool isValidOn(DateTime date) {
    return isActive && date.isAfter(startDate) && date.isBefore(endDate);
  }

  // Calculate discount amount for an order
  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrderValue) {
      return 0;
    }

    double discount = orderAmount * (discountPercent / 100);

    // Apply maximum discount limit if set
    if (maxDiscountValue > 0 && discount > maxDiscountValue) {
      discount = maxDiscountValue;
    }

    return discount;
  }
}