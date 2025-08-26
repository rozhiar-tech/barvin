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

  static String m0(error) => "خطأ: ${error}";

  static String m1(howMany) =>
      "${Intl.plural(howMany, zero: 'لا عناصر', one: 'عنصر واحد', other: '${howMany} عناصر')}";

  static String m2(status) => "لا توجد طلبات";

  static String m3(lat, lng) => "الموقع: (${lat}، ${lng})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("معلومات عنا"),
    "addBasket": MessageLookupByLibrary.simpleMessage("أضف إلى السلة"),
    "addNewAddress": MessageLookupByLibrary.simpleMessage("إضافة عنوان جديد"),
    "address": MessageLookupByLibrary.simpleMessage("عنوان"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("جميع الخصومات"),
    "appName": MessageLookupByLibrary.simpleMessage("بارڤین"),
    "appTitle": MessageLookupByLibrary.simpleMessage("تطبيق بارڤين"),
    "basket": MessageLookupByLibrary.simpleMessage("سلتك"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("السلة فارغة"),
    "basketTitle": MessageLookupByLibrary.simpleMessage("سلة التسوق"),
    "cashOnDelivery": MessageLookupByLibrary.simpleMessage(
      "الدفع عند الاستلام",
    ),
    "checkout": MessageLookupByLibrary.simpleMessage("الدفع"),
    "checkoutProceed": MessageLookupByLibrary.simpleMessage("المتابعة للدفع"),
    "clearBasket": MessageLookupByLibrary.simpleMessage("تم مسح السلة"),
    "contact": MessageLookupByLibrary.simpleMessage("اتصل بنا"),
    "continueAsGuest": MessageLookupByLibrary.simpleMessage("المتابعة كضيف"),
    "currencyIqd": MessageLookupByLibrary.simpleMessage("د.ع"),
    "currency_code_iqd": MessageLookupByLibrary.simpleMessage("دینار"),
    "deals": MessageLookupByLibrary.simpleMessage("الصفقات"),
    "delete": MessageLookupByLibrary.simpleMessage("حذف الحساب"),
    "delivery": MessageLookupByLibrary.simpleMessage("عنوان التسليم"),
    "deliveryFee": MessageLookupByLibrary.simpleMessage("رسوم التوصيل"),
    "deliveryInformation": MessageLookupByLibrary.simpleMessage(
      "معلومات التسليم",
    ),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage("ليس لديك حساب؟"),
    "errorWithMessage": m0,
    "facebook": MessageLookupByLibrary.simpleMessage("فيسبوك"),
    "follow": MessageLookupByLibrary.simpleMessage("تابعنا"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "تم التصميم والتطوير بواسطة وكالة يو إس تي",
    ),
    "guest": MessageLookupByLibrary.simpleMessage("ضيف"),
    "guestBannerText": MessageLookupByLibrary.simpleMessage(
      "يمكنك التصفّح كضيف، لكن تحتاج إلى حساب لإتمام الطلب.",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "يرجى تسجيل الدخول لإجراء الطلب",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("اكتب للبحث"),
    "instagram": MessageLookupByLibrary.simpleMessage("إنستغرام"),
    "itemsCount": m1,
    "language": MessageLookupByLibrary.simpleMessage("اللغة"),
    "latitude": MessageLookupByLibrary.simpleMessage("خط العرض"),
    "login": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
    "loginButton": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
    "loginIdentifierHint": MessageLookupByLibrary.simpleMessage(
      "أدخل البريد الإلكتروني أو رقم الهاتف",
    ),
    "loginIdentifierLabel": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني أو الهاتف",
    ),
    "loginInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "بيانات اعتماد غير صحيحة",
    ),
    "loginInvalidIdentifier": MessageLookupByLibrary.simpleMessage(
      "أدخل بريداً إلكترونياً أو رقم هاتف صالحاً",
    ),
    "loginMinimumChars": MessageLookupByLibrary.simpleMessage(
      "الحد الأدنى 6 أحرف",
    ),
    "loginPasswordHint": MessageLookupByLibrary.simpleMessage(
      "أدخل كلمة المرور",
    ),
    "loginPasswordLabel": MessageLookupByLibrary.simpleMessage("كلمة المرور"),
    "loginRequired": MessageLookupByLibrary.simpleMessage("مطلوب"),
    "loginSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تسجيل الدخول بنجاح!",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
    "longitude": MessageLookupByLibrary.simpleMessage("خط الطول"),
    "my_orders_title": MessageLookupByLibrary.simpleMessage("طلباتي"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "خطأ في الشبكة — يُرجى المحاولة مرة أخرى",
    ),
    "networkErrorTryAgain": MessageLookupByLibrary.simpleMessage(
      "خطأ في الشبكة — حاول مرة أخرى.",
    ),
    "newSearch": MessageLookupByLibrary.simpleMessage(
      "أدخل المصطلح واضغط على البحث",
    ),
    "noOrder": MessageLookupByLibrary.simpleMessage("لم يتم العثور على طلبات."),
    "orderOn": MessageLookupByLibrary.simpleMessage("طلب على"),
    "order_number_prefix": MessageLookupByLibrary.simpleMessage("#ORD-"),
    "orders_empty_all": MessageLookupByLibrary.simpleMessage(
      "لا توجد طلبات حتى الآن",
    ),
    "orders_empty_status": m2,
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "الرجاء تسجيل الدخول لتقديم طلبك",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("تسجيل الدخول للطلب"),
    "pack": MessageLookupByLibrary.simpleMessage("حزمة"),
    "pack_order": MessageLookupByLibrary.simpleMessage("اطلب كحزمة"),
    "pack_size": MessageLookupByLibrary.simpleMessage("حزمة واحدة"),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("طريقة الدفع"),
    "placeOrder": MessageLookupByLibrary.simpleMessage("طلب"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("الملف الشخصي"),
    "requiredField": MessageLookupByLibrary.simpleMessage("الحقل المطلوب"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("المراجعة سلة"),
    "save": MessageLookupByLibrary.simpleMessage("يحفظ"),
    "seeMore": MessageLookupByLibrary.simpleMessage("زیادە"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("إرسال الطلب"),
    "signUpAddressLabel": MessageLookupByLibrary.simpleMessage("العنوان"),
    "signUpButton": MessageLookupByLibrary.simpleMessage("إنشاء حساب"),
    "signUpCta": MessageLookupByLibrary.simpleMessage(
      "ليس لديك حساب؟ سجّل الآن",
    ),
    "signUpEmailLabel": MessageLookupByLibrary.simpleMessage(
      "البريد الإلكتروني",
    ),
    "signUpEnterAddress": MessageLookupByLibrary.simpleMessage("أدخل عنوانك"),
    "signUpEnterEmail": MessageLookupByLibrary.simpleMessage(
      "أدخل بريدك الإلكتروني",
    ),
    "signUpEnterPhone": MessageLookupByLibrary.simpleMessage("أدخل رقم الهاتف"),
    "signUpEnterYourName": MessageLookupByLibrary.simpleMessage("أدخل اسمك"),
    "signUpFullName": MessageLookupByLibrary.simpleMessage("الاسم الكامل"),
    "signUpInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "بريد إلكتروني غير صالح",
    ),
    "signUpInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "رقم هاتف غير صالح",
    ),
    "signUpLocationPicked": m3,
    "signUpNoLocationSelected": MessageLookupByLibrary.simpleMessage(
      "لم يتم اختيار موقع",
    ),
    "signUpPasswordAllowedChars": MessageLookupByLibrary.simpleMessage(
      "يُمكن أن تحتوي كلمة المرور على أحرف وأرقام ونقطة فقط",
    ),
    "signUpPasswordLabel": MessageLookupByLibrary.simpleMessage("كلمة المرور"),
    "signUpPasswordMin8": MessageLookupByLibrary.simpleMessage(
      "يجب أن تكون كلمة المرور ٨ أحرف فأكثر",
    ),
    "signUpPhoneLabel": MessageLookupByLibrary.simpleMessage("الهاتف"),
    "signUpPickPhotoPrompt": MessageLookupByLibrary.simpleMessage(
      "يرجى اختيار صورة",
    ),
    "signUpSelectLocationError": MessageLookupByLibrary.simpleMessage(
      "يرجى تحديد موقعك على الخريطة",
    ),
    "signUpSuccess": MessageLookupByLibrary.simpleMessage(
      "تم إنشاء الحساب! يرجى تسجيل الدخول.",
    ),
    "signUpTitle": MessageLookupByLibrary.simpleMessage("إنشاء حساب"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "تسجيل الدخول لعرض الطلبات",
    ),
    "slogan": MessageLookupByLibrary.simpleMessage(
      "نحن نسعى جاهدين لتوصيل الضروريات اليومية بأسعار رائعة وبسرعة.",
    ),
    "snackBasketEmpty": MessageLookupByLibrary.simpleMessage("سلتك فارغة."),
    "snackNetworkError": MessageLookupByLibrary.simpleMessage(
      "خطأ في الشبكة — يرجى المحاولة مرة أخرى",
    ),
    "snackOrderFail": MessageLookupByLibrary.simpleMessage("فشل تنفيذ الطلب"),
    "snackOrderSuccess": MessageLookupByLibrary.simpleMessage(
      "تم تنفيذ الطلب بنجاح!",
    ),
    "snackSignInToOrder": MessageLookupByLibrary.simpleMessage(
      "يرجى تسجيل الدخول لإتمام الطلب.",
    ),
    "snackWhatsAppOpenFail": MessageLookupByLibrary.simpleMessage(
      "تعذّر فتح واتساب على هذا الجهاز.",
    ),
    "status_delivered": MessageLookupByLibrary.simpleMessage("تم التسليم"),
    "status_pending": MessageLookupByLibrary.simpleMessage("قيد الانتظار"),
    "subtotal": MessageLookupByLibrary.simpleMessage("المجموع الفرعي"),
    "tDeals": MessageLookupByLibrary.simpleMessage("عروض اليوم"),
    "tab_delivered": MessageLookupByLibrary.simpleMessage("تم التسليم"),
    "tab_ordered": MessageLookupByLibrary.simpleMessage("تم الطلب"),
    "tab_pending": MessageLookupByLibrary.simpleMessage("قيد الانتظار"),
    "tap": MessageLookupByLibrary.simpleMessage("انقر لإضافة عنوانك"),
    "tapToPickLocation": MessageLookupByLibrary.simpleMessage(
      "انقر لاختيار الموقع",
    ),
    "tiktok": MessageLookupByLibrary.simpleMessage("تيك توك"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("إجمالي الإنفاق"),
    "total_label": MessageLookupByLibrary.simpleMessage("الإجمالي:"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("اكتب للبحث"),
    "unit": MessageLookupByLibrary.simpleMessage("وحدة"),
    "waAddress": MessageLookupByLibrary.simpleMessage("العنوان"),
    "waDelivery": MessageLookupByLibrary.simpleMessage("التوصيل"),
    "waFree": MessageLookupByLibrary.simpleMessage("مجانًا"),
    "waHeader": MessageLookupByLibrary.simpleMessage("🧾 بارفين – طلب جديد"),
    "waName": MessageLookupByLibrary.simpleMessage("الاسم"),
    "waPhone": MessageLookupByLibrary.simpleMessage("الهاتف"),
    "waSubtotal": MessageLookupByLibrary.simpleMessage("المجموع الفرعي"),
    "waTotalUpper": MessageLookupByLibrary.simpleMessage("الإجمالي"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("مرحبًا بعودتك!"),
    "whatsAppTooltip": MessageLookupByLibrary.simpleMessage("أرسل عبر واتساب"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("طلباتك"),
  };
}
