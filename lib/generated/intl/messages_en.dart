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

  static String m0(howMany) =>
      "${Intl.plural(howMany, zero: 'No items', one: '1 item', other: '${howMany} items')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("My Barvin App"),
    "basket": MessageLookupByLibrary.simpleMessage("Your basket"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("Basket is empty"),
    "clearBasket": MessageLookupByLibrary.simpleMessage("Basket cleared"),
    "delivery": MessageLookupByLibrary.simpleMessage("Delivery"),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t Have an Account?",
    ),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "Designed and Developed by UST Agency",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "Please sign in to place your order",
    ),
    "itemsCount": m0,
    "language": MessageLookupByLibrary.simpleMessage("language"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "logout": MessageLookupByLibrary.simpleMessage("logout"),
    "noOrder": MessageLookupByLibrary.simpleMessage("No orders found."),
    "orderOn": MessageLookupByLibrary.simpleMessage("Order on"),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "Please sign in to place your order",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("Sign in to Order"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "seeMore": MessageLookupByLibrary.simpleMessage("See More"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("Send Order"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "Sign In to View Orders",
    ),
    "subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("Total Spent"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back!"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("Your Orders"),
  };
}
