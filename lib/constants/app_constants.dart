import 'package:flutter/material.dart';

/// Application-wide color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary colors
  static const Color primary = Color(0xFF567765);
  static const Color primaryLight = Color(0xFFbed6be);
  static const Color primaryDark = Color(0xFF5D8A4E);
  static const Color secondary = Color(0xFF6D8474);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Colors.grey;
  static const Color textWhite = Colors.white;
  
  // Background colors
  static const Color backgroundLight = Color(0xffD3E4C4);
  static const Color backgroundCard = Color(0xffFEFAE0);
  static const Color backgroundGrey = Color(0xFFF7F7F7);
  static const Color backgroundGreen = Color(0xFFE5EED8);
  
  // Border colors
  static const Color borderLight = Color(0xFFEFEFEF);
  static const Color borderMedium = Color(0xFFE6E6E6);
  static const Color borderGreen = Color(0xFFE6ECE8);
  static const Color borderGreenLight = Color(0xFFE0E7E3);
  
  // Accent colors
  static const Color whatsAppGreen = Color(0xFF25D366);
  static const Color errorRed = Color(0xFFC43D3D);
  static const Color successGreen = Color(0xFF4BCF7B);
  static const Color dividerGreen = Color(0xFFC9D5CF);
  static const Color dividerLight = Color(0xFFDBE7E1);
  static const Color dividerBackground = Color(0xFFF6FBF7);
  
  // Status colors
  static const Color redAccent = Colors.redAccent;
  static const Color orange = Colors.orange;
  static const Color grey = Colors.grey;
}

/// Application-wide size and spacing constants
class AppSizes {
  AppSizes._(); // Private constructor to prevent instantiation

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 6.0;
  static const double spacingSM = 8.0;
  static const double spacingM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingMD = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusMD = 14.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  
  // Icon sizes
  static const double iconXS = 14.0;
  static const double iconS = 18.0;
  static const double iconM = 22.0;
  static const double iconL = 28.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 64.0;
  
  // Font sizes
  static const double fontSizeXS = 9.0;
  static const double fontSizeS = 11.0;
  static const double fontSizeSM = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  
  // Button heights
  static const double buttonHeightS = 34.0;
  static const double buttonHeightM = 46.0;
  static const double buttonHeightL = 50.0;
  
  // Card dimensions
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 8.0;
}

/// API endpoint paths
class AppEndpoints {
  AppEndpoints._(); // Private constructor to prevent instantiation

  // Auth endpoints
  static const String authLogin = '/auth/login';
  static const String authRegisterStart = '/auth/register-start';
  static const String authRegisterComplete = '/auth/register-complete';
  static const String authRequestResetOtp = '/auth/request-reset-otp';
  static const String authResetWithOtp = '/auth/reset-with-otp';
  
  // Product endpoints
  static const String items = '/items';
  static const String categories = '/categories';
  static const String categoriesWithItems = '/categories/with-items';
  static const String search = '/search';
  
  // Order endpoints
  static const String orders = '/orders';
  static const String ordersUser = '/orders/user';
  
  // Discount endpoints
  static const String discounts = '/discounts';
  static const String discountsPublic = '/discounts/public';
  
  // Other endpoints
  static const String ads = '/ads';
  static const String handworks = '/handworks';
  static const String foodBaskets = '/foodbaskets';
  static const String settings = '/settings';
  static const String notificationsRegisterToken = '/notifications/register-token';
  static const String appVersion = '/app-version';
  static const String uiLayoutsHome = '/ui-layouts/home';
  static const String featuredCategorySetsResolve = '/featured-category-sets/resolve';
}

/// Legacy color constants for backward compatibility
/// These will be gradually replaced with AppColors
@Deprecated('Use AppColors.primary instead')
const Color primaryColor = AppColors.primary;

@Deprecated('Use AppColors.primaryLight instead')
const Color primaryColorLight = AppColors.primaryLight;

@Deprecated('Use AppColors.secondary instead')
const Color secondaryColor = AppColors.secondary;

@Deprecated('Use AppColors.textPrimary instead')
const Color textColor = AppColors.textPrimary;

