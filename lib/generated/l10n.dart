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
    final name =
        (locale.countryCode?.isEmpty ?? false)
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

  /// `Your Orders`
  String get yourOrders {
    return Intl.message('Your Orders', name: 'yourOrders', desc: '', args: []);
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
