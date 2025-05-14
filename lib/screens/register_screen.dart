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

  // Password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  // Registration method
  void _register() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
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
              'Registration failed. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get auth provider for loading state
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
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
                  'Create an Account',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 20),

                // Full Name TextField
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
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

                // Password TextField
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
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
                  labelText: 'Confirm Password',
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
                  labelText: 'Shipping Address',
                  validator: Validators.validateShippingAddress,
                ),
                SizedBox(height: 20),

                // Register Button
                PrimaryButton(
                  text: 'Register',
                  isLoading: authProvider.isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}