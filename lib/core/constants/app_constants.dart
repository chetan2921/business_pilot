/// App-wide constants for BusinessPilot
library;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'BusinessPilot';
  static const String appVersion = '1.0.0';

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Padding & Spacing
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Local Storage Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
}

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String invoices = '/invoices';
  static const String customers = '/customers';
  static const String aiChat = '/ai-chat';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Inventory routes
  static const String products = '/products';
  static const String addProduct = '/add-product';
  static const String barcodeScanner = '/barcode-scanner';
  static const String quickSale = '/quick-sale';
  static const String inventoryInsights = '/inventory-insights';
  static const String analytics = '/analytics';
}
