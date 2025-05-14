class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String shippingAddress;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.shippingAddress = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer', // Mặc định là customer nếu không có role
      shippingAddress: json['shippingAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'shippingAddress': shippingAddress,
    };
  }


  // Getter kiểm tra admin
  bool get isAdmin => role.toLowerCase() == 'admin';
}