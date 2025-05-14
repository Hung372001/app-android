import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/routes.dart';

class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Kiểm tra đăng nhập
        if (!authProvider.isLoggedIn) {
          // Chưa đăng nhập, chuyển đến màn hình login
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Vui lòng đăng nhập'),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
                    child: Text('Đăng nhập'),
                  )
                ],
              ),
            ),
          );
        }

        // Kiểm tra quyền admin
        if (!authProvider.isAdmin) {
          // Không phải admin, chuyển về trang chủ
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bạn không có quyền truy cập'),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.home),
                    child: Text('Quay lại trang chủ'),
                  )
                ],
              ),
            ),
          );
        }

        // Là admin, cho phép truy cập
        return child;
      },
    );
  }
}

// Hàm tiện ích để bao bọc route admin
Widget adminRouteWrapper(Widget child) {
  return AdminRouteGuard(child: child);
}