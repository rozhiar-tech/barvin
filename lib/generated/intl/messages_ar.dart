// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
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
  String get localeName => 'ar';

  static String m0(howMany) =>
      "${Intl.plural(howMany, zero: 'لا عناصر', one: 'عنصر واحد', other: '${howMany} عناصر')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("تطبيق بارڤين"),
    "basket": MessageLookupByLibrary.simpleMessage("سلتك"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("السلة فارغة"),
    "clearBasket": MessageLookupByLibrary.simpleMessage("تم مسح السلة"),
    "delivery": MessageLookupByLibrary.simpleMessage("توصيل"),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage("ليس لديك حساب؟"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "تم التصميم والتطوير بواسطة وكالة يو إس تي",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "يرجى تسجيل الدخول لإجراء الطلب",
    ),
    "itemsCount": m0,
    "language": MessageLookupByLibrary.simpleMessage("اللغة"),
    "login": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
    "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "noOrder": MessageLookupByLibrary.simpleMessage("لم يتم العثور على طلبات."),
    "orderOn": MessageLookupByLibrary.simpleMessage("طلب على"),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "الرجاء تسجيل الدخول لتقديم طلبك",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("تسجيل الدخول للطلب"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("الملف الشخصي"),
    "seeMore": MessageLookupByLibrary.simpleMessage("زیادە"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("إرسال الطلب"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "تسجيل الدخول لعرض الطلبات",
    ),
    "subtotal": MessageLookupByLibrary.simpleMessage("المجموع الفرعي"),
    "total": MessageLookupByLibrary.simpleMessage("المجموع"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("إجمالي الإنفاق"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("مرحبًا بعودتك!"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("طلباتك"),
  };
}
