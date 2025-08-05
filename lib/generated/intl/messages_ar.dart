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
    "addNewAddress": MessageLookupByLibrary.simpleMessage("إضافة عنوان جديد"),
    "address": MessageLookupByLibrary.simpleMessage("عنوان"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("جميع الخصومات"),
    "appTitle": MessageLookupByLibrary.simpleMessage("تطبيق بارڤين"),
    "basket": MessageLookupByLibrary.simpleMessage("سلتك"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("السلة فارغة"),
    "cashOnDelivery": MessageLookupByLibrary.simpleMessage(
      "الدفع عند الاستلام",
    ),
    "checkout": MessageLookupByLibrary.simpleMessage("الدفع"),
    "clearBasket": MessageLookupByLibrary.simpleMessage("تم مسح السلة"),
    "deals": MessageLookupByLibrary.simpleMessage("الصفقات"),
    "delivery": MessageLookupByLibrary.simpleMessage("توصيل"),
    "deliveryFee": MessageLookupByLibrary.simpleMessage("رسوم التوصيل"),
    "deliveryInformation": MessageLookupByLibrary.simpleMessage(
      "معلومات التسليم",
    ),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage("ليس لديك حساب؟"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "تم التصميم والتطوير بواسطة وكالة يو إس تي",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "يرجى تسجيل الدخول لإجراء الطلب",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("اكتب للبحث"),
    "itemsCount": m0,
    "language": MessageLookupByLibrary.simpleMessage("اللغة"),
    "latitude": MessageLookupByLibrary.simpleMessage("خط العرض"),
    "login": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
    "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "longitude": MessageLookupByLibrary.simpleMessage("خط الطول"),
    "newSearch": MessageLookupByLibrary.simpleMessage(
      "أدخل المصطلح واضغط على البحث",
    ),
    "noOrder": MessageLookupByLibrary.simpleMessage("لم يتم العثور على طلبات."),
    "orderOn": MessageLookupByLibrary.simpleMessage("طلب على"),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "الرجاء تسجيل الدخول لتقديم طلبك",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("تسجيل الدخول للطلب"),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("طريقة الدفع"),
    "placeOrder": MessageLookupByLibrary.simpleMessage("طلب"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("الملف الشخصي"),
    "requiredField": MessageLookupByLibrary.simpleMessage("الحقل المطلوب"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("المراجعة سلة"),
    "save": MessageLookupByLibrary.simpleMessage("يحفظ"),
    "seeMore": MessageLookupByLibrary.simpleMessage("زیادە"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("إرسال الطلب"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "تسجيل الدخول لعرض الطلبات",
    ),
    "subtotal": MessageLookupByLibrary.simpleMessage("المجموع الفرعي"),
    "tDeals": MessageLookupByLibrary.simpleMessage("عروض اليوم"),
    "tapToPickLocation": MessageLookupByLibrary.simpleMessage(
      "انقر لاختيار الموقع",
    ),
    "total": MessageLookupByLibrary.simpleMessage("المجموع"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("إجمالي الإنفاق"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("اكتب للبحث"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("مرحبًا بعودتك!"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("طلباتك"),
  };
}
