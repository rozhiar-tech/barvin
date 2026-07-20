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

  static String m0(status) => "Failed to load items (HTTP ${status}).";

  static String m1(error) => "Error: ${error}";

  static String m2(count) => "Available: ${count}";

  static String m3(howMany) =>
      "${Intl.plural(howMany, zero: 'No items', one: '1 item', other: '${howMany} items')}";

  static String m4(error) => "Error getting location: ${error}";

  static String m5(status) => "No ${status} orders";

  static String m6(seconds) => "Resend in ${seconds}s";

  static String m7(destination) => "We sent a code to ${destination}.";

  static String m8(lat, lng) => "Location: (${lat}, ${lng})";

  static String m9(version) => "Required version: ${version}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About Us"),
    "addBasket": MessageLookupByLibrary.simpleMessage("Add to Basket"),
    "addNewAddress": MessageLookupByLibrary.simpleMessage("Add New Address"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "adsTitle": MessageLookupByLibrary.simpleMessage("Ads"),
    "adsVisitLink": MessageLookupByLibrary.simpleMessage("Visit link"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("All Discounts"),
    "appName": MessageLookupByLibrary.simpleMessage("Barvin"),
    "appTitle": MessageLookupByLibrary.simpleMessage("My Barvin App"),
    "backToLogin": MessageLookupByLibrary.simpleMessage("Back to login"),
    "basket": MessageLookupByLibrary.simpleMessage("Your basket"),
    "basketBadgeCustom": MessageLookupByLibrary.simpleMessage("Custom basket"),
    "basketBadgePreset": MessageLookupByLibrary.simpleMessage("Food basket"),
    "basketBuilderAddToCart": MessageLookupByLibrary.simpleMessage(
      "Add selected items to cart",
    ),
    "basketBuilderAdding": MessageLookupByLibrary.simpleMessage("Adding…"),
    "basketBuilderLoadError": MessageLookupByLibrary.simpleMessage(
      "Unable to load inventory.",
    ),
    "basketBuilderLoadFailed": m0,
    "basketBuilderPickAtLeastOne": MessageLookupByLibrary.simpleMessage(
      "Pick at least one item.",
    ),
    "basketBuilderSaveError": MessageLookupByLibrary.simpleMessage(
      "Unable to update your basket.",
    ),
    "basketBuilderSearchHint": MessageLookupByLibrary.simpleMessage(
      "Search items…",
    ),
    "basketBuilderTitle": MessageLookupByLibrary.simpleMessage(
      "Create Food Basket",
    ),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("Basket is empty"),
    "basketSectionCustom": MessageLookupByLibrary.simpleMessage(
      "Your custom baskets",
    ),
    "basketSectionPreset": MessageLookupByLibrary.simpleMessage(
      "Preset food baskets",
    ),
    "basketSectionRegular": MessageLookupByLibrary.simpleMessage(
      "Regular items",
    ),
    "basketTab": MessageLookupByLibrary.simpleMessage("Basket"),
    "basketTitle": MessageLookupByLibrary.simpleMessage("Your Basket"),
    "bestPriceCampaign": MessageLookupByLibrary.simpleMessage(
      "Best price: Campaign discount",
    ),
    "bestPriceItem": MessageLookupByLibrary.simpleMessage(
      "Best price: Item discount",
    ),
    "campaign": MessageLookupByLibrary.simpleMessage("Campaign"),
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
    "createBasketCardBody": MessageLookupByLibrary.simpleMessage(
      "Pick any items from our catalog and send your personalized basket.",
    ),
    "createBasketCardTitle": MessageLookupByLibrary.simpleMessage(
      "Create your own basket",
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
    "errorWithMessage": m1,
    "facebook": MessageLookupByLibrary.simpleMessage("Facebook"),
    "featuredCategoriesTitle": MessageLookupByLibrary.simpleMessage(
      "Featured categories",
    ),
    "follow": MessageLookupByLibrary.simpleMessage("Follow us"),
    "foodBasketCustomizeCta": MessageLookupByLibrary.simpleMessage(
      "Customize & Order",
    ),
    "foodBasketSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Food Baskets",
    ),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "Designed and Developed by UST Agency",
    ),
    "forgotChooseMethod": MessageLookupByLibrary.simpleMessage(
      "How would you like to receive the code?",
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
    "handWorkSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Barvin Press",
    ),
    "handworkAvailableLabel": m2,
    "handworkContactButton": MessageLookupByLibrary.simpleMessage(
      "For inquiries contact us",
    ),
    "handworkDesiredQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Quantity",
    ),
    "handworkNoDescription": MessageLookupByLibrary.simpleMessage(
      "No description provided.",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("Type To Search"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "instagram": MessageLookupByLibrary.simpleMessage("Instagram"),
    "item": MessageLookupByLibrary.simpleMessage("Item"),
    "itemsCount": m3,
    "language": MessageLookupByLibrary.simpleMessage("language"),
    "latitude": MessageLookupByLibrary.simpleMessage("latitude"),
    "locationConfirm": MessageLookupByLibrary.simpleMessage("Confirm Location"),
    "locationErrorGeneric": m4,
    "locationFallbackHint": MessageLookupByLibrary.simpleMessage(
      "Showing a default location — tap the map to set your delivery point",
    ),
    "locationGettingYours": MessageLookupByLibrary.simpleMessage(
      "Getting your location…",
    ),
    "locationPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Location permission denied",
    ),
    "locationPermissionDeniedForever": MessageLookupByLibrary.simpleMessage(
      "Location permissions are permanently denied. Enable in Settings.",
    ),
    "locationPickerTitle": MessageLookupByLibrary.simpleMessage(
      "Pick Your Location",
    ),
    "locationServicesDisabled": MessageLookupByLibrary.simpleMessage(
      "Location services are disabled. Please enable GPS.",
    ),
    "locationTapHint": MessageLookupByLibrary.simpleMessage(
      "Tap on the map to select your delivery location",
    ),
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
    "orderHoursBody": MessageLookupByLibrary.simpleMessage(
      "Orders are processed from 8:00 AM to 10:00 PM. Requests after 10:00 PM will be delayed until 8:00 AM the next day.",
    ),
    "orderHoursHeading": MessageLookupByLibrary.simpleMessage("Order hours"),
    "orderOn": MessageLookupByLibrary.simpleMessage("Order on"),
    "orderTab": MessageLookupByLibrary.simpleMessage("Orders"),
    "order_number_prefix": MessageLookupByLibrary.simpleMessage("#ORD-"),
    "orders_empty_all": MessageLookupByLibrary.simpleMessage("No orders yet"),
    "orders_empty_status": m5,
    "otpCodeLabel": MessageLookupByLibrary.simpleMessage("6-digit code"),
    "otpConfirmPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "otpCreateAccountButton": MessageLookupByLibrary.simpleMessage(
      "Create Account",
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
    "otpResendIn": m6,
    "otpResent": MessageLookupByLibrary.simpleMessage(
      "Verification code re-sent.",
    ),
    "otpSentTo": m7,
    "otpSubmit": MessageLookupByLibrary.simpleMessage("Reset password"),
    "otpTitle": MessageLookupByLibrary.simpleMessage(
      "Enter the code we emailed you",
    ),
    "otpTitlePhone": MessageLookupByLibrary.simpleMessage(
      "Enter the code we texted you",
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
    "presetBasketDescription": MessageLookupByLibrary.simpleMessage(
      "Preset basket from Barvin.",
    ),
    "profileTab": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "qty": MessageLookupByLibrary.simpleMessage("Qty"),
    "receiptBranchLabel": MessageLookupByLibrary.simpleMessage("Branch/Store:"),
    "receiptColCode": MessageLookupByLibrary.simpleMessage("Item code"),
    "receiptColName": MessageLookupByLibrary.simpleMessage("Item"),
    "receiptColNo": MessageLookupByLibrary.simpleMessage("No."),
    "receiptColQty": MessageLookupByLibrary.simpleMessage("Qty"),
    "receiptColTotal": MessageLookupByLibrary.simpleMessage("Total"),
    "receiptColUnitPrice": MessageLookupByLibrary.simpleMessage("Unit price"),
    "receiptCurrencyLabel": MessageLookupByLibrary.simpleMessage("Currency:"),
    "receiptCustomerNameLabel": MessageLookupByLibrary.simpleMessage(
      "Customer name:",
    ),
    "receiptDateLabel": MessageLookupByLibrary.simpleMessage("Date:"),
    "receiptDeliveryFeeLabel": MessageLookupByLibrary.simpleMessage(
      "Delivery fee:",
    ),
    "receiptDiscountLabel": MessageLookupByLibrary.simpleMessage("Discount:"),
    "receiptGrandTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Grand Total:",
    ),
    "receiptLaborFeeLabel": MessageLookupByLibrary.simpleMessage("Labor cost:"),
    "receiptNumberLabel": MessageLookupByLibrary.simpleMessage("Receipt #:"),
    "receiptSignatureLabel": MessageLookupByLibrary.simpleMessage(
      "Customer signature:",
    ),
    "receiptSubtotalLabel": MessageLookupByLibrary.simpleMessage("Subtotal:"),
    "receiptTitle": MessageLookupByLibrary.simpleMessage("Sale Receipt"),
    "requiredField": MessageLookupByLibrary.simpleMessage("Required Field"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("Review Basket"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "seeMore": MessageLookupByLibrary.simpleMessage("See More"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("Send Order"),
    "signUpAddressLabel": MessageLookupByLibrary.simpleMessage("Address"),
    "signUpBack": MessageLookupByLibrary.simpleMessage("Back"),
    "signUpButton": MessageLookupByLibrary.simpleMessage("Sign Up"),
    "signUpContinue": MessageLookupByLibrary.simpleMessage("Continue"),
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
    "signUpLocationPicked": m8,
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
    "signUpSkipForNow": MessageLookupByLibrary.simpleMessage("Skip for now"),
    "signUpSkipHint": MessageLookupByLibrary.simpleMessage(
      "You can add your delivery address anytime from your profile.",
    ),
    "signUpStepAccount": MessageLookupByLibrary.simpleMessage(
      "Step 1 of 2 · Account",
    ),
    "signUpStepProfile": MessageLookupByLibrary.simpleMessage(
      "Step 2 of 2 · Delivery details",
    ),
    "signUpSuccess": MessageLookupByLibrary.simpleMessage("Welcome to Barvin!"),
    "signUpTitle": MessageLookupByLibrary.simpleMessage("Create Account"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "Sign In to View Orders",
    ),
    "slogan": MessageLookupByLibrary.simpleMessage(
      "About Barvin  Barvin is a comprehensive procurement application dedicated to providing high quality products at unbeatable prices to both businesses and retail consumers. Barvbin provides a range of essentials—from coffee, tea and cheese to cereals, oils, spices, beverages and canned goods—ensuring that everyone, whether a business or an individual, has access to high-quality products. Our mission is to bridge the gap between price and quality, and to encourage all our customers to grow.",
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
    "tapToViewMore": MessageLookupByLibrary.simpleMessage("Tap to view more"),
    "tiktok": MessageLookupByLibrary.simpleMessage("TikTok"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("Total Spent"),
    "total_label": MessageLookupByLibrary.simpleMessage("Total:"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("Type To Search"),
    "unit": MessageLookupByLibrary.simpleMessage("Unit"),
    "updateButton": MessageLookupByLibrary.simpleMessage("Update app"),
    "updateRequiredBody": MessageLookupByLibrary.simpleMessage(
      "A new version of Barvin is available. Please update the app to continue.",
    ),
    "updateRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Update required",
    ),
    "updateStoreLinkHint": MessageLookupByLibrary.simpleMessage(
      "If the button doesn’t work, open your app store and search for “Barvin”.",
    ),
    "updateVersionLabel": m9,
    "verificationEmailOption": MessageLookupByLibrary.simpleMessage(
      "Email OTP",
    ),
    "verificationMethodLabel": MessageLookupByLibrary.simpleMessage(
      "Verification method",
    ),
    "verificationPhoneOption": MessageLookupByLibrary.simpleMessage(
      "Phone OTP",
    ),
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
    "whatsappHelpBody": MessageLookupByLibrary.simpleMessage(
      "If the checkout button doesn’t work, you can contact our team on WhatsApp.",
    ),
    "whatsappHelpCta": MessageLookupByLibrary.simpleMessage(
      "WhatsApp order support",
    ),
    "yourOrders": MessageLookupByLibrary.simpleMessage("Your Orders"),
  };
}
