import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import providers
import '../providers/auth_provider.dart';

// Import utils
import '../utils/routes.dart';
import '../utils/validators.dart';

// Import widgets
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _phoneController = TextEditingController(); // Thêm controller cho số điện thoại

  // Password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Checkbox state
  bool _agreedToTerms = false; // Thêm trạng thái đồng ý điều khoản

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shippingAddressController.dispose();
    _phoneController.dispose(); // Giải phóng controller số điện thoại
    super.dispose();
  }

  // Registration method
  void _register() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      // Check if user agreed to terms
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vui lòng đồng ý với điều khoản dịch vụ để tiếp tục.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Attempt registration
      bool success = await authProvider.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        shippingAddress: _shippingAddressController.text.trim(),
      );

      if (success) {
        // Navigate to home screen on successful registration
        Navigator.of(context).pushReplacementNamed(Routes.home);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Đăng ký thất bại. Vui lòng thử lại.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Đăng ký bằng Google

  @override
  Widget build(BuildContext context) {
    // Get auth provider for loading state
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Registration form widgets
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 20),

                // Full Name TextField
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Họ và tên',
                  validator: Validators.validateFullName,
                ),
                SizedBox(height: 15),

                // Email TextField
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                SizedBox(height: 15),

                // Phone TextField

                SizedBox(height: 15),

                // Password TextField
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Confirm Password TextField
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Xác nhận mật khẩu',
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => Validators.validateConfirmPassword(
                      _passwordController.text,
                      value
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Shipping Address TextField
                CustomTextField(
                  controller: _shippingAddressController,
                  labelText: 'Địa chỉ giao hàng',
                  validator: Validators.validateShippingAddress,
                ),
                SizedBox(height: 20),

                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: Text(
                          'Tôi đồng ý với điều khoản dịch vụ và chính sách bảo mật',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Register Button
                PrimaryButton(
                  text: 'Đăng ký',
                  isLoading: authProvider.isLoading,
                  onPressed: _register,
                ),

                SizedBox(height: 20),

                // Divider with "Or" text
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Hoặc'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: 20),

                // Google Sign In Button

              ],
            ),
          ),
        ),
      ),
    );
  }
}