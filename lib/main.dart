import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Providers
import './providers/auth_provider.dart';
import './providers/product_provider.dart';
import './providers/cart_provider.dart';
import './providers/admin_product_provider.dart';

// Import Screens
import './screens/login_screen.dart';
import './screens/register_screen.dart';
import './screens/home_screen.dart';
import './screens/profile_screen.dart';
import './screens/product_catalog_screen.dart';
import './screens/product_details_screen.dart';
// Import Admin Screens
import './screens/admin/admin_dashboard_screen.dart';
import './screens/admin/admin_product_list_screen.dart';
import './screens/admin/admin_product_management_screen.dart';

// Import Utils
import './utils/routes.dart';
import './utils/admin_route_guard.dart';

// Import Models
import './models/admin_product_model.dart';

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

        // Main App Routes
        Routes.home: (context) => HomeScreen(),
        Routes.profile: (context) => ProfileScreen(),
        Routes.productCatalog: (context) => ProductCatalogScreen(),

        // Admin Routes (Wrapped with AdminRouteGuard)
        Routes.adminDashboard: (context) => adminRouteWrapper(AdminDashboardScreen()),
        Routes.adminProductList: (context) => adminRouteWrapper(AdminProductListScreen()),
        Routes.adminProductAdd: (context) => adminRouteWrapper(AdminProductManagementScreen()),

        // Dynamic route for product details
        Routes.productDetails: (context) => ProductDetailsScreen(
          productId: ModalRoute.of(context)!.settings.arguments as String,
        ),

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