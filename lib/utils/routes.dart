class Routes {
  // Authentication Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main App Routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String productCatalog = '/product-catalog';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String categoryProducts = '/category-products';

  // Order Routes
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderHistory = '/order-history';
  static const String orderDetails = '/order-details';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';

  // Admin Product Routes
  static const String adminProductList = '/admin/products';
  static const String adminProductAdd = '/admin/products/add';
  static const String adminProductEdit = '/admin/products/edit';

  // Admin Order Routes
  static const String adminOrderManagement = '/admin/orders';
  static const String adminOrderDetails = '/admin/orders/details';

  // Admin User Routes
  static const String adminUserManagement = '/admin/users';

  // Admin Coupon Routes
  static const String adminCouponManagement = '/admin/coupons';

  // Admin Dashboard Routes
  static const String adminSalesDashboard = '/admin/sales-dashboard';
  static const String adminCustomerSupport = '/admin/customer-support';
}