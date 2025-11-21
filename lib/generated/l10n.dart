// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `My Barvin App`
  String get appTitle {
    return Intl.message('My Barvin App', name: 'appTitle', desc: '', args: []);
  }

  /// `Profile`
  String get profileTitle {
    return Intl.message('Profile', name: 'profileTitle', desc: '', args: []);
  }

  /// `language`
  String get language {
    return Intl.message('language', name: 'language', desc: '', args: []);
  }

  /// `logout`
  String get logout {
    return Intl.message('logout', name: 'logout', desc: '', args: []);
  }

  /// `See More`
  String get seeMore {
    return Intl.message('See More', name: 'seeMore', desc: '', args: []);
  }

  /// `Designed and Developed by UST Agency`
  String get footerCredit {
    return Intl.message(
      'Designed and Developed by UST Agency',
      name: 'footerCredit',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Please sign in to place your order`
  String get guestModeMessage {
    return Intl.message(
      'Please sign in to place your order',
      name: 'guestModeMessage',
      desc: 'Shown in basket when the user is not signed in',
      args: [],
    );
  }

  /// `Guest`
  String get guest {
    return Intl.message('Guest', name: 'guest', desc: '', args: []);
  }

  /// `Campaign`
  String get campaign {
    return Intl.message('Campaign', name: 'campaign', desc: '', args: []);
  }

  /// `Best price: Item discount`
  String get bestPriceItem {
    return Intl.message(
      'Best price: Item discount',
      name: 'bestPriceItem',
      desc: '',
      args: [],
    );
  }

  /// `Best price: Campaign discount`
  String get bestPriceCampaign {
    return Intl.message(
      'Best price: Campaign discount',
      name: 'bestPriceCampaign',
      desc: '',
      args: [],
    );
  }

  /// `Item`
  String get item {
    return Intl.message('Item', name: 'item', desc: '', args: []);
  }

  /// `Your basket`
  String get basket {
    return Intl.message('Your basket', name: 'basket', desc: '', args: []);
  }

  /// `Delivery`
  String get delivery {
    return Intl.message('Delivery', name: 'delivery', desc: '', args: []);
  }

  /// `Subtotal`
  String get subtotal {
    return Intl.message('Subtotal', name: 'subtotal', desc: '', args: []);
  }

  /// `My Orders`
  String get my_orders_title {
    return Intl.message(
      'My Orders',
      name: 'my_orders_title',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get tab_pending {
    return Intl.message('Pending', name: 'tab_pending', desc: '', args: []);
  }

  /// `Ordered`
  String get tab_ordered {
    return Intl.message('Ordered', name: 'tab_ordered', desc: '', args: []);
  }

  /// `Delivered`
  String get tab_delivered {
    return Intl.message('Delivered', name: 'tab_delivered', desc: '', args: []);
  }

  /// `No orders yet`
  String get orders_empty_all {
    return Intl.message(
      'No orders yet',
      name: 'orders_empty_all',
      desc: '',
      args: [],
    );
  }

  /// `Qty`
  String get qty {
    return Intl.message('Qty', name: 'qty', desc: '', args: []);
  }

  /// `No {status} orders`
  String orders_empty_status(Object status) {
    return Intl.message(
      'No $status orders',
      name: 'orders_empty_status',
      desc: '',
      args: [status],
    );
  }

  /// `#ORD-`
  String get order_number_prefix {
    return Intl.message(
      '#ORD-',
      name: 'order_number_prefix',
      desc: '',
      args: [],
    );
  }

  /// `Total:`
  String get total_label {
    return Intl.message('Total:', name: 'total_label', desc: '', args: []);
  }

  /// `IQD`
  String get currency_code_iqd {
    return Intl.message('IQD', name: 'currency_code_iqd', desc: '', args: []);
  }

  /// `1 pack`
  String get pack_size {
    return Intl.message('1 pack', name: 'pack_size', desc: '', args: []);
  }

  /// `Pack`
  String get pack {
    return Intl.message('Pack', name: 'pack', desc: '', args: []);
  }

  /// `Order as pack`
  String get pack_order {
    return Intl.message(
      'Order as pack',
      name: 'pack_order',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get status_pending {
    return Intl.message('Pending', name: 'status_pending', desc: '', args: []);
  }

  /// `Delivered`
  String get status_delivered {
    return Intl.message(
      'Delivered',
      name: 'status_delivered',
      desc: '',
      args: [],
    );
  }

  /// `Enter email or phone number`
  String get loginIdentifierHint {
    return Intl.message(
      'Enter email or phone number',
      name: 'loginIdentifierHint',
      desc: '',
      args: [],
    );
  }

  /// `Email or Phone`
  String get loginIdentifierLabel {
    return Intl.message(
      'Email or Phone',
      name: 'loginIdentifierLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password`
  String get loginPasswordHint {
    return Intl.message(
      'Enter your password',
      name: 'loginPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get loginPasswordLabel {
    return Intl.message(
      'Password',
      name: 'loginPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get loginRequired {
    return Intl.message('Required', name: 'loginRequired', desc: '', args: []);
  }

  /// `Enter valid email or phone`
  String get loginInvalidIdentifier {
    return Intl.message(
      'Enter valid email or phone',
      name: 'loginInvalidIdentifier',
      desc: '',
      args: [],
    );
  }

  /// `Minimum 6 chars`
  String get loginMinimumChars {
    return Intl.message(
      'Minimum 6 chars',
      name: 'loginMinimumChars',
      desc: '',
      args: [],
    );
  }

  /// `Log In`
  String get loginButton {
    return Intl.message('Log In', name: 'loginButton', desc: '', args: []);
  }

  /// `Don't have an account? Sign Up`
  String get signUpCta {
    return Intl.message(
      'Don\'t have an account? Sign Up',
      name: 'signUpCta',
      desc: '',
      args: [],
    );
  }

  /// `You can browse as a guest, but need an account to order.`
  String get guestBannerText {
    return Intl.message(
      'You can browse as a guest, but need an account to order.',
      name: 'guestBannerText',
      desc: '',
      args: [],
    );
  }

  /// `Continue as Guest`
  String get continueAsGuest {
    return Intl.message(
      'Continue as Guest',
      name: 'continueAsGuest',
      desc: '',
      args: [],
    );
  }

  /// `Signed in successfully!`
  String get loginSuccess {
    return Intl.message(
      'Signed in successfully!',
      name: 'loginSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Invalid credentials`
  String get loginInvalidCredentials {
    return Intl.message(
      'Invalid credentials',
      name: 'loginInvalidCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Network error. Please try again.`
  String get networkError {
    return Intl.message(
      'Network error. Please try again.',
      name: 'networkError',
      desc: '',
      args: [],
    );
  }

  /// `Your Basket`
  String get basketTitle {
    return Intl.message('Your Basket', name: 'basketTitle', desc: '', args: []);
  }

  /// `Send via WhatsApp`
  String get whatsAppTooltip {
    return Intl.message(
      'Send via WhatsApp',
      name: 'whatsAppTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get signUpTitle {
    return Intl.message(
      'Create Account',
      name: 'signUpTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please pick a photo`
  String get signUpPickPhotoPrompt {
    return Intl.message(
      'Please pick a photo',
      name: 'signUpPickPhotoPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get signUpFullName {
    return Intl.message(
      'Full Name',
      name: 'signUpFullName',
      desc: '',
      args: [],
    );
  }

  /// `Enter your name`
  String get signUpEnterYourName {
    return Intl.message(
      'Enter your name',
      name: 'signUpEnterYourName',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get signUpEmailLabel {
    return Intl.message('Email', name: 'signUpEmailLabel', desc: '', args: []);
  }

  /// `Enter your email`
  String get signUpEnterEmail {
    return Intl.message(
      'Enter your email',
      name: 'signUpEnterEmail',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get signUpInvalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'signUpInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get signUpPasswordLabel {
    return Intl.message(
      'Password',
      name: 'signUpPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Password must be ≥8 chars`
  String get signUpPasswordMin8 {
    return Intl.message(
      'Password must be ≥8 chars',
      name: 'signUpPasswordMin8',
      desc: '',
      args: [],
    );
  }

  /// `Password may only contain letters, numbers, and “.”`
  String get signUpPasswordAllowedChars {
    return Intl.message(
      'Password may only contain letters, numbers, and “.”',
      name: 'signUpPasswordAllowedChars',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get signUpPhoneLabel {
    return Intl.message('Phone', name: 'signUpPhoneLabel', desc: '', args: []);
  }

  /// `Enter phone`
  String get signUpEnterPhone {
    return Intl.message(
      'Enter phone',
      name: 'signUpEnterPhone',
      desc: '',
      args: [],
    );
  }

  /// `Invalid phone`
  String get signUpInvalidPhone {
    return Intl.message(
      'Invalid phone',
      name: 'signUpInvalidPhone',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get forgotPasswordLink {
    return Intl.message(
      'Forgot password?',
      name: 'forgotPasswordLink',
      desc: '',
      args: [],
    );
  }

  /// `Reset your password`
  String get forgotTitle {
    return Intl.message(
      'Reset your password',
      name: 'forgotTitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get forgotEmailLabel {
    return Intl.message('Email', name: 'forgotEmailLabel', desc: '', args: []);
  }

  /// `Send code`
  String get forgotSendCode {
    return Intl.message(
      'Send code',
      name: 'forgotSendCode',
      desc: '',
      args: [],
    );
  }

  /// `If that email exists, we sent you a code.`
  String get forgotSentCheckEmail {
    return Intl.message(
      'If that email exists, we sent you a code.',
      name: 'forgotSentCheckEmail',
      desc: '',
      args: [],
    );
  }

  /// `Back to login`
  String get backToLogin {
    return Intl.message(
      'Back to login',
      name: 'backToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code we emailed you`
  String get otpTitle {
    return Intl.message(
      'Enter the code we emailed you',
      name: 'otpTitle',
      desc: '',
      args: [],
    );
  }

  /// `6-digit code`
  String get otpCodeLabel {
    return Intl.message(
      '6-digit code',
      name: 'otpCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get otpNewPasswordLabel {
    return Intl.message(
      'New password',
      name: 'otpNewPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get otpConfirmPasswordLabel {
    return Intl.message(
      'Confirm password',
      name: 'otpConfirmPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get otpSubmit {
    return Intl.message(
      'Reset password',
      name: 'otpSubmit',
      desc: '',
      args: [],
    );
  }

  /// `Resend`
  String get otpResend {
    return Intl.message('Resend', name: 'otpResend', desc: '', args: []);
  }

  /// `Resend in {seconds}s`
  String otpResendIn(Object seconds) {
    return Intl.message(
      'Resend in ${seconds}s',
      name: 'otpResendIn',
      desc: '',
      args: [seconds],
    );
  }

  /// `You can resend a new code`
  String get otpYouCanResend {
    return Intl.message(
      'You can resend a new code',
      name: 'otpYouCanResend',
      desc: '',
      args: [],
    );
  }

  /// `Enter the 6-digit code`
  String get otpInvalidFormat {
    return Intl.message(
      'Enter the 6-digit code',
      name: 'otpInvalidFormat',
      desc: '',
      args: [],
    );
  }

  /// `Passwords don’t match`
  String get otpPasswordMismatch {
    return Intl.message(
      'Passwords don’t match',
      name: 'otpPasswordMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Invalid code or expired`
  String get otpInvalidCode {
    return Intl.message(
      'Invalid code or expired',
      name: 'otpInvalidCode',
      desc: '',
      args: [],
    );
  }

  /// `Password updated! You can log in now.`
  String get passwordUpdatedSuccess {
    return Intl.message(
      'Password updated! You can log in now.',
      name: 'passwordUpdatedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get genericError {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'genericError',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get signUpAddressLabel {
    return Intl.message(
      'Address',
      name: 'signUpAddressLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter your address`
  String get signUpEnterAddress {
    return Intl.message(
      'Enter your address',
      name: 'signUpEnterAddress',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Orders`
  String get orderTab {
    return Intl.message('Orders', name: 'orderTab', desc: '', args: []);
  }

  /// `Profile`
  String get profileTab {
    return Intl.message('Profile', name: 'profileTab', desc: '', args: []);
  }

  /// `Basket`
  String get basketTab {
    return Intl.message('Basket', name: 'basketTab', desc: '', args: []);
  }

  /// `Location: ({lat}, {lng})`
  String signUpLocationPicked(Object lat, Object lng) {
    return Intl.message(
      'Location: ($lat, $lng)',
      name: 'signUpLocationPicked',
      desc: '',
      args: [lat, lng],
    );
  }

  /// `No location selected`
  String get signUpNoLocationSelected {
    return Intl.message(
      'No location selected',
      name: 'signUpNoLocationSelected',
      desc: '',
      args: [],
    );
  }

  /// `Please select your location on map`
  String get signUpSelectLocationError {
    return Intl.message(
      'Please select your location on map',
      name: 'signUpSelectLocationError',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up`
  String get signUpButton {
    return Intl.message('Sign Up', name: 'signUpButton', desc: '', args: []);
  }

  /// `Account created! Please sign in.`
  String get signUpSuccess {
    return Intl.message(
      'Account created! Please sign in.',
      name: 'signUpSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Error: {error}`
  String errorWithMessage(Object error) {
    return Intl.message(
      'Error: $error',
      name: 'errorWithMessage',
      desc: '',
      args: [error],
    );
  }

  /// `Network error — try again.`
  String get networkErrorTryAgain {
    return Intl.message(
      'Network error — try again.',
      name: 'networkErrorTryAgain',
      desc: '',
      args: [],
    );
  }

  /// `🧾 Barvin – New order`
  String get waHeader {
    return Intl.message(
      '🧾 Barvin – New order',
      name: 'waHeader',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get waName {
    return Intl.message('Name', name: 'waName', desc: '', args: []);
  }

  /// `Phone`
  String get waPhone {
    return Intl.message('Phone', name: 'waPhone', desc: '', args: []);
  }

  /// `Address`
  String get waAddress {
    return Intl.message('Address', name: 'waAddress', desc: '', args: []);
  }

  /// `Subtotal`
  String get waSubtotal {
    return Intl.message('Subtotal', name: 'waSubtotal', desc: '', args: []);
  }

  /// `Delivery`
  String get waDelivery {
    return Intl.message('Delivery', name: 'waDelivery', desc: '', args: []);
  }

  /// `TOTAL`
  String get waTotalUpper {
    return Intl.message('TOTAL', name: 'waTotalUpper', desc: '', args: []);
  }

  /// `FREE`
  String get waFree {
    return Intl.message('FREE', name: 'waFree', desc: '', args: []);
  }

  /// `IQD`
  String get currencyIqd {
    return Intl.message('IQD', name: 'currencyIqd', desc: '', args: []);
  }

  /// `Unit`
  String get unit {
    return Intl.message('Unit', name: 'unit', desc: '', args: []);
  }

  /// `Your basket is empty.`
  String get snackBasketEmpty {
    return Intl.message(
      'Your basket is empty.',
      name: 'snackBasketEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Could not open WhatsApp on this device.`
  String get snackWhatsAppOpenFail {
    return Intl.message(
      'Could not open WhatsApp on this device.',
      name: 'snackWhatsAppOpenFail',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to place an order.`
  String get snackSignInToOrder {
    return Intl.message(
      'Please sign in to place an order.',
      name: 'snackSignInToOrder',
      desc: '',
      args: [],
    );
  }

  /// `Order placed successfully!`
  String get snackOrderSuccess {
    return Intl.message(
      'Order placed successfully!',
      name: 'snackOrderSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to place order`
  String get snackOrderFail {
    return Intl.message(
      'Failed to place order',
      name: 'snackOrderFail',
      desc: '',
      args: [],
    );
  }

  /// `Network error — please try again`
  String get snackNetworkError {
    return Intl.message(
      'Network error — please try again',
      name: 'snackNetworkError',
      desc: '',
      args: [],
    );
  }

  /// `Add to Basket`
  String get addBasket {
    return Intl.message('Add to Basket', name: 'addBasket', desc: '', args: []);
  }

  /// `Proceed to Checkout`
  String get checkoutProceed {
    return Intl.message(
      'Proceed to Checkout',
      name: 'checkoutProceed',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get total {
    return Intl.message('Total', name: 'total', desc: '', args: []);
  }

  /// `Basket cleared`
  String get clearBasket {
    return Intl.message(
      'Basket cleared',
      name: 'clearBasket',
      desc: '',
      args: [],
    );
  }

  /// `Total Spent`
  String get totalSpent {
    return Intl.message('Total Spent', name: 'totalSpent', desc: '', args: []);
  }

  /// `No orders found.`
  String get noOrder {
    return Intl.message(
      'No orders found.',
      name: 'noOrder',
      desc: '',
      args: [],
    );
  }

  /// `Order on`
  String get orderOn {
    return Intl.message('Order on', name: 'orderOn', desc: '', args: []);
  }

  /// `Checkout`
  String get checkout {
    return Intl.message('Checkout', name: 'checkout', desc: '', args: []);
  }

  /// `Delivery Information`
  String get deliveryInformation {
    return Intl.message(
      'Delivery Information',
      name: 'deliveryInformation',
      desc: '',
      args: [],
    );
  }

  /// `Add New Address`
  String get addNewAddress {
    return Intl.message(
      'Add New Address',
      name: 'addNewAddress',
      desc: '',
      args: [],
    );
  }

  /// `Payment Method`
  String get paymentMethod {
    return Intl.message(
      'Payment Method',
      name: 'paymentMethod',
      desc: '',
      args: [],
    );
  }

  /// `Cash On Delivery`
  String get cashOnDelivery {
    return Intl.message(
      'Cash On Delivery',
      name: 'cashOnDelivery',
      desc: '',
      args: [],
    );
  }

  /// `Review Basket`
  String get reviewBasket {
    return Intl.message(
      'Review Basket',
      name: 'reviewBasket',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Fee`
  String get deliveryFee {
    return Intl.message(
      'Delivery Fee',
      name: 'deliveryFee',
      desc: '',
      args: [],
    );
  }

  /// `Place Order`
  String get placeOrder {
    return Intl.message('Place Order', name: 'placeOrder', desc: '', args: []);
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `Required Field`
  String get requiredField {
    return Intl.message(
      'Required Field',
      name: 'requiredField',
      desc: '',
      args: [],
    );
  }

  /// `latitude`
  String get latitude {
    return Intl.message('latitude', name: 'latitude', desc: '', args: []);
  }

  /// `longitude`
  String get longitude {
    return Intl.message('longitude', name: 'longitude', desc: '', args: []);
  }

  /// `Delete account`
  String get delete {
    return Intl.message('Delete account', name: 'delete', desc: '', args: []);
  }

  /// `Delivery Address`
  String get delivery2 {
    return Intl.message(
      'Delivery Address',
      name: 'delivery2',
      desc: '',
      args: [],
    );
  }

  /// `Tap to add your address`
  String get tap {
    return Intl.message(
      'Tap to add your address',
      name: 'tap',
      desc: '',
      args: [],
    );
  }

  /// `Type To Search`
  String get typeSearch {
    return Intl.message(
      'Type To Search',
      name: 'typeSearch',
      desc: '',
      args: [],
    );
  }

  /// `Enter a term and press search`
  String get newSearch {
    return Intl.message(
      'Enter a term and press search',
      name: 'newSearch',
      desc: '',
      args: [],
    );
  }

  /// `Type To Search`
  String get hint {
    return Intl.message('Type To Search', name: 'hint', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `About Us`
  String get about {
    return Intl.message('About Us', name: 'about', desc: '', args: []);
  }

  /// `Barvin`
  String get appName {
    return Intl.message('Barvin', name: 'appName', desc: '', args: []);
  }

  /// `About Barvin  Barvin is a comprehensive procurement application dedicated to providing high quality products at unbeatable prices to both businesses and retail consumers. Barvbin provides a range of essentials—from coffee, tea and cheese to cereals, oils, spices, beverages and canned goods—ensuring that everyone, whether a business or an individual, has access to high-quality products. Our mission is to bridge the gap between price and quality, and to encourage all our customers to grow.`
  String get slogan {
    return Intl.message(
      'About Barvin  Barvin is a comprehensive procurement application dedicated to providing high quality products at unbeatable prices to both businesses and retail consumers. Barvbin provides a range of essentials—from coffee, tea and cheese to cereals, oils, spices, beverages and canned goods—ensuring that everyone, whether a business or an individual, has access to high-quality products. Our mission is to bridge the gap between price and quality, and to encourage all our customers to grow.',
      name: 'slogan',
      desc: '',
      args: [],
    );
  }

  /// `Your Orders`
  String get yourOrders {
    return Intl.message('Your Orders', name: 'yourOrders', desc: '', args: []);
  }

  /// `Today's Deals`
  String get tDeals {
    return Intl.message('Today\'s Deals', name: 'tDeals', desc: '', args: []);
  }

  /// `All Discounts`
  String get allDiscount {
    return Intl.message(
      'All Discounts',
      name: 'allDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Contact Us`
  String get contact {
    return Intl.message('Contact Us', name: 'contact', desc: '', args: []);
  }

  /// `Follow us`
  String get follow {
    return Intl.message('Follow us', name: 'follow', desc: '', args: []);
  }

  /// `Instagram`
  String get instagram {
    return Intl.message('Instagram', name: 'instagram', desc: '', args: []);
  }

  /// `TikTok`
  String get tiktok {
    return Intl.message('TikTok', name: 'tiktok', desc: '', args: []);
  }

  /// `Facebook`
  String get facebook {
    return Intl.message('Facebook', name: 'facebook', desc: '', args: []);
  }

  /// `Sign In to View Orders`
  String get singInOrder {
    return Intl.message(
      'Sign In to View Orders',
      name: 'singInOrder',
      desc: '',
      args: [],
    );
  }

  /// `Don't Have an Account?`
  String get dontHaveAnAccount {
    return Intl.message(
      'Don\'t Have an Account?',
      name: 'dontHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to place your order`
  String get pSignin {
    return Intl.message(
      'Please sign in to place your order',
      name: 'pSignin',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to Order`
  String get pSignin2 {
    return Intl.message(
      'Sign in to Order',
      name: 'pSignin2',
      desc: '',
      args: [],
    );
  }

  /// `Basket is empty`
  String get basketEmpty {
    return Intl.message(
      'Basket is empty',
      name: 'basketEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Tap To Pick Location`
  String get tapToPickLocation {
    return Intl.message(
      'Tap To Pick Location',
      name: 'tapToPickLocation',
      desc: '',
      args: [],
    );
  }

  /// `Send Order`
  String get sendOrder {
    return Intl.message('Send Order', name: 'sendOrder', desc: '', args: []);
  }

  /// `Welcome back!`
  String get welcomeBack {
    return Intl.message(
      'Welcome back!',
      name: 'welcomeBack',
      desc: '',
      args: [],
    );
  }

  /// `Deals`
  String get deals {
    return Intl.message('Deals', name: 'deals', desc: '', args: []);
  }

  /// `{howMany, plural, =0{No items} =1{1 item} other{{howMany} items}}`
  String itemsCount(num howMany) {
    return Intl.plural(
      howMany,
      zero: 'No items',
      one: '1 item',
      other: '$howMany items',
      name: 'itemsCount',
      desc: 'How many items in the basket',
      args: [howMany],
    );
  }

  /// `Order hours`
  String get orderHoursHeading {
    return Intl.message(
      'Order hours',
      name: 'orderHoursHeading',
      desc: '',
      args: [],
    );
  }

  /// `Orders are processed from 8:00 AM to 10:00 PM. Requests after 10:00 PM will be delayed until 8:00 AM the next day.`
  String get orderHoursBody {
    return Intl.message(
      'Orders are processed from 8:00 AM to 10:00 PM. Requests after 10:00 PM will be delayed until 8:00 AM the next day.',
      name: 'orderHoursBody',
      desc: '',
      args: [],
    );
  }

  /// `If the checkout button doesn’t work, you can contact our team on WhatsApp.`
  String get whatsappHelpBody {
    return Intl.message(
      'If the checkout button doesn’t work, you can contact our team on WhatsApp.',
      name: 'whatsappHelpBody',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp order support`
  String get whatsappHelpCta {
    return Intl.message(
      'WhatsApp order support',
      name: 'whatsappHelpCta',
      desc: '',
      args: [],
    );
  }

  /// `Your custom baskets`
  String get basketSectionCustom {
    return Intl.message(
      'Your custom baskets',
      name: 'basketSectionCustom',
      desc: '',
      args: [],
    );
  }

  /// `Preset food baskets`
  String get basketSectionPreset {
    return Intl.message(
      'Preset food baskets',
      name: 'basketSectionPreset',
      desc: '',
      args: [],
    );
  }

  /// `Regular items`
  String get basketSectionRegular {
    return Intl.message(
      'Regular items',
      name: 'basketSectionRegular',
      desc: '',
      args: [],
    );
  }

  /// `Custom basket`
  String get basketBadgeCustom {
    return Intl.message(
      'Custom basket',
      name: 'basketBadgeCustom',
      desc: '',
      args: [],
    );
  }

  /// `Food basket`
  String get basketBadgePreset {
    return Intl.message(
      'Food basket',
      name: 'basketBadgePreset',
      desc: '',
      args: [],
    );
  }

  /// `Barvin Press`
  String get handWorkSectionTitle {
    return Intl.message(
      'Barvin Press',
      name: 'handWorkSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Food Baskets`
  String get foodBasketSectionTitle {
    return Intl.message(
      'Food Baskets',
      name: 'foodBasketSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create your own basket`
  String get createBasketCardTitle {
    return Intl.message(
      'Create your own basket',
      name: 'createBasketCardTitle',
      desc: '',
      args: [],
    );
  }

  /// `Pick any items from our catalog and send your personalized basket.`
  String get createBasketCardBody {
    return Intl.message(
      'Pick any items from our catalog and send your personalized basket.',
      name: 'createBasketCardBody',
      desc: '',
      args: [],
    );
  }

  /// `Preset basket from Barvin.`
  String get presetBasketDescription {
    return Intl.message(
      'Preset basket from Barvin.',
      name: 'presetBasketDescription',
      desc: '',
      args: [],
    );
  }

  /// `No description provided.`
  String get handworkNoDescription {
    return Intl.message(
      'No description provided.',
      name: 'handworkNoDescription',
      desc: '',
      args: [],
    );
  }

  /// `Customize & Order`
  String get foodBasketCustomizeCta {
    return Intl.message(
      'Customize & Order',
      name: 'foodBasketCustomizeCta',
      desc: '',
      args: [],
    );
  }

  /// `Featured categories`
  String get featuredCategoriesTitle {
    return Intl.message(
      'Featured categories',
      name: 'featuredCategoriesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tap to view more`
  String get tapToViewMore {
    return Intl.message(
      'Tap to view more',
      name: 'tapToViewMore',
      desc: '',
      args: [],
    );
  }

  /// `For inquiries contact us`
  String get handworkContactButton {
    return Intl.message(
      'For inquiries contact us',
      name: 'handworkContactButton',
      desc: '',
      args: [],
    );
  }

  /// `Available: {count}`
  String handworkAvailableLabel(Object count) {
    return Intl.message(
      'Available: $count',
      name: 'handworkAvailableLabel',
      desc: '',
      args: [count],
    );
  }

  /// `Quantity`
  String get handworkDesiredQuantityLabel {
    return Intl.message(
      'Quantity',
      name: 'handworkDesiredQuantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Verification method`
  String get verificationMethodLabel {
    return Intl.message(
      'Verification method',
      name: 'verificationMethodLabel',
      desc: '',
      args: [],
    );
  }

  /// `Phone OTP`
  String get verificationPhoneOption {
    return Intl.message(
      'Phone OTP',
      name: 'verificationPhoneOption',
      desc: '',
      args: [],
    );
  }

  /// `Email OTP`
  String get verificationEmailOption {
    return Intl.message(
      'Email OTP',
      name: 'verificationEmailOption',
      desc: '',
      args: [],
    );
  }

  /// `How would you like to receive the code?`
  String get forgotChooseMethod {
    return Intl.message(
      'How would you like to receive the code?',
      name: 'forgotChooseMethod',
      desc: '',
      args: [],
    );
  }

  /// `We sent a code to {destination}.`
  String otpSentTo(Object destination) {
    return Intl.message(
      'We sent a code to $destination.',
      name: 'otpSentTo',
      desc: '',
      args: [destination],
    );
  }

  /// `Verification code re-sent.`
  String get otpResent {
    return Intl.message(
      'Verification code re-sent.',
      name: 'otpResent',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code we texted you`
  String get otpTitlePhone {
    return Intl.message(
      'Enter the code we texted you',
      name: 'otpTitlePhone',
      desc: '',
      args: [],
    );
  }

  /// `Update required`
  String get updateRequiredTitle {
    return Intl.message(
      'Update required',
      name: 'updateRequiredTitle',
      desc: '',
      args: [],
    );
  }

  /// `A new version of Barvin is available. Please update the app to continue.`
  String get updateRequiredBody {
    return Intl.message(
      'A new version of Barvin is available. Please update the app to continue.',
      name: 'updateRequiredBody',
      desc: '',
      args: [],
    );
  }

  /// `Update app`
  String get updateButton {
    return Intl.message('Update app', name: 'updateButton', desc: '', args: []);
  }

  /// `If the button doesn’t work, open your app store and search for “Barvin”.`
  String get updateStoreLinkHint {
    return Intl.message(
      'If the button doesn’t work, open your app store and search for “Barvin”.',
      name: 'updateStoreLinkHint',
      desc: '',
      args: [],
    );
  }

  /// `Required version: {version}`
  String updateVersionLabel(Object version) {
    return Intl.message(
      'Required version: $version',
      name: 'updateVersionLabel',
      desc: '',
      args: [version],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'ku'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
