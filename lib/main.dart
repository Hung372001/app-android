import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/admin_user_provider.dart';
import 'package:untitled/screens/admin_user_management_screen.dart';

// Import Providers
import './providers/auth_provider.dart';
import './providers/product_provider.dart';
import './providers/cart_provider.dart';
import './providers/admin_product_provider.dart';
import './providers/admin_order_provider.dart';
import './providers/admin_coupon_provider.dart';
import './providers/order_provider.dart';

// Import Screens
import './screens/login_screen.dart';
import './screens/register_screen.dart';
import './screens/home_screen.dart';
import './screens/profile_screen.dart';
import './screens/product_catalog_screen.dart';
import './screens/product_details_screen.dart';
import './screens/cart_screen.dart';
import './screens/category_product_screen.dart';

// Import Order Screens
import './screens/checkout_screen.dart';
import './screens/order_success_screen.dart';
import './screens/order_history_screen.dart';
import './screens/order_details_screen.dart';

// Import Admin Screens
import './screens/admin/admin_dashboard_screen.dart';
import './screens/admin/admin_product_list_screen.dart';
import './screens/admin/admin_product_management_screen.dart';
import './screens/admin/admin_order_management_screen.dart';
import './screens/admin/admin_coupon_management_screen.dart';

// Import Utils
import './utils/routes.dart';
import './utils/admin_route_guard.dart';

// Import Models
import './models/admin_product_model.dart';
import './models/order_model.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Log error to a service or show a user-friendly error dialog
  };

  // Catch synchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log error
    print('Uncaught error: $error');
    print('Stack trace: $stack');
    return true;
  };
  runApp(
    MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // Product Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (context) => ProductProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousProductProvider) =>
              ProductProvider(authProvider),
        ),

        // Admin Product Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, AdminProductProvider>(
          create: (context) => AdminProductProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousAdminProductProvider) =>
              AdminProductProvider(authProvider),
        ),

        // Cart Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousCartProvider) =>
              CartProvider(authProvider),
        ),

        // Admin Order Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, AdminOrderProvider>(
          create: (context) => AdminOrderProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousOrderProvider) =>
              AdminOrderProvider(authProvider),
        ),

        // Admin Coupon Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, AdminCouponProvider>(
          create: (context) => AdminCouponProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousCouponProvider) =>
              AdminCouponProvider(authProvider),
        ),

        // Order Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => OrderProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousOrderProvider) =>
              OrderProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminUserProvider>(
          create: (context) => AdminUserProvider(
              Provider.of<AuthProvider>(context, listen: false)
          ),
          update: (context, authProvider, previousOrderProvider) =>
              AdminUserProvider(authProvider),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Initial route
      initialRoute: Routes.home,

      // Define routes
      routes: {
        // Authentication Routes
        Routes.login: (context) => LoginScreen(),
        Routes.register: (context) => RegisterScreen(),
        // Routes.forgotPassword: (context) => ForgotPasswordScreen(),

        // Main App Routes
        Routes.home: (context) => HomeScreen(),
        Routes.profile: (context) => ProfileScreen(),
        Routes.productCatalog: (context) => ProductCatalogScreen(),
        Routes.cart: (context) => CartScreen(),

        // Order Routes
        Routes.checkout: (context) => CheckoutScreen(),
        Routes.orderHistory: (context) => OrderHistoryScreen(),

        // Admin Routes (Wrapped with AdminRouteGuard)
        Routes.adminDashboard: (context) => adminRouteWrapper(AdminDashboardScreen()),
        Routes.adminProductList: (context) => adminRouteWrapper(AdminProductListScreen()),
        Routes.adminProductAdd: (context) => adminRouteWrapper(AdminProductManagementScreen()),
        Routes.adminOrderManagement: (context) => adminRouteWrapper(AdminOrderManagementScreen()),
        Routes.adminCouponManagement: (context) => adminRouteWrapper(AdminCouponManagementScreen()),
        Routes.adminUserManagement: (context) => adminRouteWrapper(AdminUserManagementScreen()),

        // Dynamic route for product details
        Routes.productDetails: (context) => ProductDetailsScreen(
          productId: ModalRoute.of(context)!.settings.arguments as String,
        ),

        // Dynamic route for category products
        Routes.categoryProducts: (context) => CategoryProductScreen(
          category: ModalRoute.of(context)!.settings.arguments as String,
        ),

        // Dynamic route for order details
        Routes.orderDetails: (context) => OrderDetailsScreen(),

        // Dynamic route for order success
        Routes.orderSuccess: (context) => OrderSuccessScreen(),

        // Dynamic route for product edit (Admin only)
        Routes.adminProductEdit: (context) => adminRouteWrapper(
            AdminProductManagementScreen(
              existingProduct: ModalRoute.of(context)!.settings.arguments as AdminProduct,
            )
        ),
      },
    );
  }
}