// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ku locale. All the
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
  String get localeName => 'ku';

  static String m0(howMany) =>
      "${Intl.plural(howMany, zero: 'هیچ بابەتێک نییە', one: ' یەک دانە', other: '${howMany} چەندە')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("برڤین بەرنامە"),
    "basket": MessageLookupByLibrary.simpleMessage("سەتلی داواکاری"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("سەتلەکە بەتالە"),
    "clearBasket": MessageLookupByLibrary.simpleMessage("سەتلەکە بەتال کرا"),
    "delivery": MessageLookupByLibrary.simpleMessage("گەیاندن"),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage("ئەکاونتت نییە؟"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "دیزاین کردنو پەرە پێدان لەلایەن یوئێستی ئەیجنسی",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "تکایە بچۆ ژوورەوە بۆ داواکردنی داواکاری",
    ),
    "itemsCount": m0,
    "language": MessageLookupByLibrary.simpleMessage("زمان"),
    "login": MessageLookupByLibrary.simpleMessage("چوونە ژوەرەوە"),
    "logout": MessageLookupByLibrary.simpleMessage("چونە دەرەوە"),
    "noOrder": MessageLookupByLibrary.simpleMessage(
      "هیچ داواکاریەک نەدۆزرایەوە",
    ),
    "orderOn": MessageLookupByLibrary.simpleMessage("داواکاری لە"),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "تکایە داخل ببە بۆ داوا کردن",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("داخل بە بۆ داواکاری"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("پەڕەی تایبەت"),
    "seeMore": MessageLookupByLibrary.simpleMessage("بینینی زیاتر"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("ناردنی داواکاری"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "داخل بوون بۆ بینینی داواکاریەکان",
    ),
    "subtotal": MessageLookupByLibrary.simpleMessage("نرخی پێش کۆتا"),
    "total": MessageLookupByLibrary.simpleMessage("کۆتا"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("کۆی مەسرەف"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("بەخێربێیتەوە!"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("داواکاریەکانت"),
  };
}
