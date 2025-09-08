// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(error) => "Error: ${error}";

  static String m1(howMany) =>
      "${Intl.plural(howMany, zero: 'No items', one: '1 item', other: '${howMany} items')}";

  static String m2(status) => "No ${status} orders";

  static String m3(seconds) => "Resend in ${seconds}s";

  static String m4(lat, lng) => "Location: (${lat}, ${lng})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About Us"),
    "addBasket": MessageLookupByLibrary.simpleMessage("Add to Basket"),
    "addNewAddress": MessageLookupByLibrary.simpleMessage("Add New Address"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("All Discounts"),
    "appName": MessageLookupByLibrary.simpleMessage("Barvin"),
    "appTitle": MessageLookupByLibrary.simpleMessage("My Barvin App"),
    "backToLogin": MessageLookupByLibrary.simpleMessage("Back to login"),
    "basket": MessageLookupByLibrary.simpleMessage("Your basket"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("Basket is empty"),
    "basketTab": MessageLookupByLibrary.simpleMessage("Basket"),
    "basketTitle": MessageLookupByLibrary.simpleMessage("Your Basket"),
    "cashOnDelivery": MessageLookupByLibrary.simpleMessage("Cash On Delivery"),
    "checkout": MessageLookupByLibrary.simpleMessage("Checkout"),
    "checkoutProceed": MessageLookupByLibrary.simpleMessage(
      "Proceed to Checkout",
    ),
    "clearBasket": MessageLookupByLibrary.simpleMessage("Basket cleared"),
    "contact": MessageLookupByLibrary.simpleMessage("Contact Us"),
    "continueAsGuest": MessageLookupByLibrary.simpleMessage(
      "Continue as Guest",
    ),
    "currencyIqd": MessageLookupByLibrary.simpleMessage("IQD"),
    "currency_code_iqd": MessageLookupByLibrary.simpleMessage("IQD"),
    "deals": MessageLookupByLibrary.simpleMessage("Deals"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete account"),
    "delivery": MessageLookupByLibrary.simpleMessage("Delivery"),
    "delivery2": MessageLookupByLibrary.simpleMessage("Delivery Address"),
    "deliveryFee": MessageLookupByLibrary.simpleMessage("Delivery Fee"),
    "deliveryInformation": MessageLookupByLibrary.simpleMessage(
      "Delivery Information",
    ),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t Have an Account?",
    ),
    "errorWithMessage": m0,
    "facebook": MessageLookupByLibrary.simpleMessage("Facebook"),
    "follow": MessageLookupByLibrary.simpleMessage("Follow us"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "Designed and Developed by UST Agency",
    ),
    "forgotEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
    "forgotPasswordLink": MessageLookupByLibrary.simpleMessage(
      "Forgot password?",
    ),
    "forgotSendCode": MessageLookupByLibrary.simpleMessage("Send code"),
    "forgotSentCheckEmail": MessageLookupByLibrary.simpleMessage(
      "If that email exists, we sent you a code.",
    ),
    "forgotTitle": MessageLookupByLibrary.simpleMessage("Reset your password"),
    "genericError": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "guest": MessageLookupByLibrary.simpleMessage("Guest"),
    "guestBannerText": MessageLookupByLibrary.simpleMessage(
      "You can browse as a guest, but need an account to order.",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "Please sign in to place your order",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("Type To Search"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "instagram": MessageLookupByLibrary.simpleMessage("Instagram"),
    "itemsCount": m1,
    "language": MessageLookupByLibrary.simpleMessage("language"),
    "latitude": MessageLookupByLibrary.simpleMessage("latitude"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginButton": MessageLookupByLibrary.simpleMessage("Log In"),
    "loginIdentifierHint": MessageLookupByLibrary.simpleMessage(
      "Enter email or phone number",
    ),
    "loginIdentifierLabel": MessageLookupByLibrary.simpleMessage(
      "Email or Phone",
    ),
    "loginInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Invalid credentials",
    ),
    "loginInvalidIdentifier": MessageLookupByLibrary.simpleMessage(
      "Enter valid email or phone",
    ),
    "loginMinimumChars": MessageLookupByLibrary.simpleMessage(
      "Minimum 6 chars",
    ),
    "loginPasswordHint": MessageLookupByLibrary.simpleMessage(
      "Enter your password",
    ),
    "loginPasswordLabel": MessageLookupByLibrary.simpleMessage("Password"),
    "loginRequired": MessageLookupByLibrary.simpleMessage("Required"),
    "loginSuccess": MessageLookupByLibrary.simpleMessage(
      "Signed in successfully!",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("logout"),
    "longitude": MessageLookupByLibrary.simpleMessage("longitude"),
    "my_orders_title": MessageLookupByLibrary.simpleMessage("My Orders"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "Network error. Please try again.",
    ),
    "networkErrorTryAgain": MessageLookupByLibrary.simpleMessage(
      "Network error — try again.",
    ),
    "newSearch": MessageLookupByLibrary.simpleMessage(
      "Enter a term and press search",
    ),
    "noOrder": MessageLookupByLibrary.simpleMessage("No orders found."),
    "orderOn": MessageLookupByLibrary.simpleMessage("Order on"),
    "orderTab": MessageLookupByLibrary.simpleMessage("Orders"),
    "order_number_prefix": MessageLookupByLibrary.simpleMessage("#ORD-"),
    "orders_empty_all": MessageLookupByLibrary.simpleMessage("No orders yet"),
    "orders_empty_status": m2,
    "otpCodeLabel": MessageLookupByLibrary.simpleMessage("6-digit code"),
    "otpConfirmPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "otpInvalidCode": MessageLookupByLibrary.simpleMessage(
      "Invalid code or expired",
    ),
    "otpInvalidFormat": MessageLookupByLibrary.simpleMessage(
      "Enter the 6-digit code",
    ),
    "otpNewPasswordLabel": MessageLookupByLibrary.simpleMessage("New password"),
    "otpPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords don’t match",
    ),
    "otpResend": MessageLookupByLibrary.simpleMessage("Resend"),
    "otpResendIn": m3,
    "otpSubmit": MessageLookupByLibrary.simpleMessage("Reset password"),
    "otpTitle": MessageLookupByLibrary.simpleMessage(
      "Enter the code we emailed you",
    ),
    "otpYouCanResend": MessageLookupByLibrary.simpleMessage(
      "You can resend a new code",
    ),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "Please sign in to place your order",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("Sign in to Order"),
    "pack": MessageLookupByLibrary.simpleMessage("Pack"),
    "pack_order": MessageLookupByLibrary.simpleMessage("Order as pack"),
    "pack_size": MessageLookupByLibrary.simpleMessage("1 pack"),
    "passwordUpdatedSuccess": MessageLookupByLibrary.simpleMessage(
      "Password updated! You can log in now.",
    ),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("Payment Method"),
    "placeOrder": MessageLookupByLibrary.simpleMessage("Place Order"),
    "profileTab": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "requiredField": MessageLookupByLibrary.simpleMessage("Required Field"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("Review Basket"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "seeMore": MessageLookupByLibrary.simpleMessage("See More"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("Send Order"),
    "signUpAddressLabel": MessageLookupByLibrary.simpleMessage("Address"),
    "signUpButton": MessageLookupByLibrary.simpleMessage("Sign Up"),
    "signUpCta": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account? Sign Up",
    ),
    "signUpEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
    "signUpEnterAddress": MessageLookupByLibrary.simpleMessage(
      "Enter your address",
    ),
    "signUpEnterEmail": MessageLookupByLibrary.simpleMessage(
      "Enter your email",
    ),
    "signUpEnterPhone": MessageLookupByLibrary.simpleMessage("Enter phone"),
    "signUpEnterYourName": MessageLookupByLibrary.simpleMessage(
      "Enter your name",
    ),
    "signUpFullName": MessageLookupByLibrary.simpleMessage("Full Name"),
    "signUpInvalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "signUpInvalidPhone": MessageLookupByLibrary.simpleMessage("Invalid phone"),
    "signUpLocationPicked": m4,
    "signUpNoLocationSelected": MessageLookupByLibrary.simpleMessage(
      "No location selected",
    ),
    "signUpPasswordAllowedChars": MessageLookupByLibrary.simpleMessage(
      "Password may only contain letters, numbers, and “.”",
    ),
    "signUpPasswordLabel": MessageLookupByLibrary.simpleMessage("Password"),
    "signUpPasswordMin8": MessageLookupByLibrary.simpleMessage(
      "Password must be ≥8 chars",
    ),
    "signUpPhoneLabel": MessageLookupByLibrary.simpleMessage("Phone"),
    "signUpPickPhotoPrompt": MessageLookupByLibrary.simpleMessage(
      "Please pick a photo",
    ),
    "signUpSelectLocationError": MessageLookupByLibrary.simpleMessage(
      "Please select your location on map",
    ),
    "signUpSuccess": MessageLookupByLibrary.simpleMessage(
      "Account created! Please sign in.",
    ),
    "signUpTitle": MessageLookupByLibrary.simpleMessage("Create Account"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "Sign In to View Orders",
    ),
    "slogan": MessageLookupByLibrary.simpleMessage(
      "We strive to deliver daily essentials at great prices, fast.",
    ),
    "snackBasketEmpty": MessageLookupByLibrary.simpleMessage(
      "Your basket is empty.",
    ),
    "snackNetworkError": MessageLookupByLibrary.simpleMessage(
      "Network error — please try again",
    ),
    "snackOrderFail": MessageLookupByLibrary.simpleMessage(
      "Failed to place order",
    ),
    "snackOrderSuccess": MessageLookupByLibrary.simpleMessage(
      "Order placed successfully!",
    ),
    "snackSignInToOrder": MessageLookupByLibrary.simpleMessage(
      "Please sign in to place an order.",
    ),
    "snackWhatsAppOpenFail": MessageLookupByLibrary.simpleMessage(
      "Could not open WhatsApp on this device.",
    ),
    "status_delivered": MessageLookupByLibrary.simpleMessage("Delivered"),
    "status_pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "tDeals": MessageLookupByLibrary.simpleMessage("Today\'s Deals"),
    "tab_delivered": MessageLookupByLibrary.simpleMessage("Delivered"),
    "tab_ordered": MessageLookupByLibrary.simpleMessage("Ordered"),
    "tab_pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "tap": MessageLookupByLibrary.simpleMessage("Tap to add your address"),
    "tapToPickLocation": MessageLookupByLibrary.simpleMessage(
      "Tap To Pick Location",
    ),
    "tiktok": MessageLookupByLibrary.simpleMessage("TikTok"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("Total Spent"),
    "total_label": MessageLookupByLibrary.simpleMessage("Total:"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("Type To Search"),
    "unit": MessageLookupByLibrary.simpleMessage("Unit"),
    "waAddress": MessageLookupByLibrary.simpleMessage("Address"),
    "waDelivery": MessageLookupByLibrary.simpleMessage("Delivery"),
    "waFree": MessageLookupByLibrary.simpleMessage("FREE"),
    "waHeader": MessageLookupByLibrary.simpleMessage("🧾 Barvin – New order"),
    "waName": MessageLookupByLibrary.simpleMessage("Name"),
    "waPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "waSubtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "waTotalUpper": MessageLookupByLibrary.simpleMessage("TOTAL"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back!"),
    "whatsAppTooltip": MessageLookupByLibrary.simpleMessage(
      "Send via WhatsApp",
    ),
    "yourOrders": MessageLookupByLibrary.simpleMessage("Your Orders"),
  };
}
