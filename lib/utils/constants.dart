class AppConstants {
  // API Base URL
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // Validation Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';

  // Styling
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
}