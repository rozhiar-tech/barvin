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

  static String m0(error) => "هەڵە: ${error}";

  static String m1(howMany) =>
      "${Intl.plural(howMany, zero: 'هیچ بابەتێک نییە', one: ' یەک دانە', other: '${howMany} چەندە')}";

  static String m2(status) => "هیچ ئۆردەرێک نییە";

  static String m3(seconds) => "دوبارە ناردنەوە لە {چرکە}s";

  static String m4(lat, lng) => "شوێن: (${lat}، ${lng})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("دەربارەی ئێمە"),
    "addBasket": MessageLookupByLibrary.simpleMessage("زیاد بکە بۆ سەبەتە"),
    "addNewAddress": MessageLookupByLibrary.simpleMessage(
      "ناونیشانی نوێ زیاد بکە",
    ),
    "address": MessageLookupByLibrary.simpleMessage("ناونیشان"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("هەموو دەسکاونتەکان"),
    "appName": MessageLookupByLibrary.simpleMessage("بارڤین"),
    "appTitle": MessageLookupByLibrary.simpleMessage("برڤین بەرنامە"),
    "backToLogin": MessageLookupByLibrary.simpleMessage(
      "گەڕانەوە بۆ چوونەژوورەوە",
    ),
    "basket": MessageLookupByLibrary.simpleMessage("سەتلی داواکاری"),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("سەتلەکە بەتالە"),
    "basketTab": MessageLookupByLibrary.simpleMessage("سەبەتە"),
    "basketTitle": MessageLookupByLibrary.simpleMessage("سەبەتەکەت"),
    "bestPriceCampaign": MessageLookupByLibrary.simpleMessage(
      "باشترین نرخ: داشکاندنی کەمپەین",
    ),
    "bestPriceItem": MessageLookupByLibrary.simpleMessage(
      "باشترین نرخ: داشکاندنی بابەت",
    ),
    "campaign": MessageLookupByLibrary.simpleMessage("کەمپەین"),
    "cashOnDelivery": MessageLookupByLibrary.simpleMessage(
      "پارەدان کاتی پێ گەیشتن",
    ),
    "checkout": MessageLookupByLibrary.simpleMessage("داوا کردن"),
    "checkoutProceed": MessageLookupByLibrary.simpleMessage(
      "بەردەوام ببە بۆ پارەدان",
    ),
    "clearBasket": MessageLookupByLibrary.simpleMessage("سەتلەکە بەتال کرا"),
    "contact": MessageLookupByLibrary.simpleMessage("پەیوەندیمان پێوە بکەن"),
    "continueAsGuest": MessageLookupByLibrary.simpleMessage(
      "بە میوانی بەردەوام بە",
    ),
    "currencyIqd": MessageLookupByLibrary.simpleMessage("د.ع"),
    "currency_code_iqd": MessageLookupByLibrary.simpleMessage("دینار"),
    "deals": MessageLookupByLibrary.simpleMessage("ئۆفەرەکان"),
    "delete": MessageLookupByLibrary.simpleMessage("ئەکاونت بسڕەوە"),
    "delivery": MessageLookupByLibrary.simpleMessage("ناونیشانی گەیاندن"),
    "deliveryFee": MessageLookupByLibrary.simpleMessage("کرێی گەیاندن"),
    "deliveryInformation": MessageLookupByLibrary.simpleMessage(
      "زانیاری گەیاندن",
    ),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage("ئەکاونتت نییە؟"),
    "errorWithMessage": m0,
    "facebook": MessageLookupByLibrary.simpleMessage("فەیسبووک"),
    "follow": MessageLookupByLibrary.simpleMessage("فۆڵۆومان بکەن"),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "دیزاین کردنو پەرە پێدان لەلایەن یوئێستی ئەیجنسی",
    ),
    "forgotEmailLabel": MessageLookupByLibrary.simpleMessage("ئیمەیڵ"),
    "forgotPasswordLink": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی لەبیر کردووە؟",
    ),
    "forgotSendCode": MessageLookupByLibrary.simpleMessage("کۆد بنێرە"),
    "forgotSentCheckEmail": MessageLookupByLibrary.simpleMessage(
      "ئەگەر ئەو ئیمەیڵە بوونی هەبێت، ئێمە کۆدێکمان بۆ ناردیت.",
    ),
    "forgotTitle": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی خۆت ڕێست بکەرەوە",
    ),
    "genericError": MessageLookupByLibrary.simpleMessage(
      "شتێک هەڵە بوو. تکایە دووبارە هەوڵبدەرەوە.",
    ),
    "guest": MessageLookupByLibrary.simpleMessage("میوان"),
    "guestBannerText": MessageLookupByLibrary.simpleMessage(
      "دەتوانیت وەک میوان بگەڕێیت، بەڵام بۆ داواکردن پێویستە هەژمارێک هەبێت.",
    ),
    "guestModeMessage": MessageLookupByLibrary.simpleMessage(
      "تکایە بچۆ ژوورەوە بۆ داواکردنی داواکاری",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("بنووسە بۆ گەڕان"),
    "home": MessageLookupByLibrary.simpleMessage("ماڵەوە"),
    "instagram": MessageLookupByLibrary.simpleMessage("ئینستاگرام"),
    "item": MessageLookupByLibrary.simpleMessage("بابەت"),
    "itemsCount": m1,
    "language": MessageLookupByLibrary.simpleMessage("زمان"),
    "latitude": MessageLookupByLibrary.simpleMessage("پانی"),
    "login": MessageLookupByLibrary.simpleMessage("چوونە ژوەرەوە"),
    "loginButton": MessageLookupByLibrary.simpleMessage("چوونەژوورەوە"),
    "loginIdentifierHint": MessageLookupByLibrary.simpleMessage(
      "ئیمەیل یان ژمارەی تەلەفۆنت بنووسە",
    ),
    "loginIdentifierLabel": MessageLookupByLibrary.simpleMessage(
      "ئیمەیل یان تەلەفۆن",
    ),
    "loginInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "زانیارییەکان نادروستن",
    ),
    "loginInvalidIdentifier": MessageLookupByLibrary.simpleMessage(
      "ئیمەیل یان ژمارەی تەلەفۆنی دروست بنووسە",
    ),
    "loginMinimumChars": MessageLookupByLibrary.simpleMessage("کەمترین ٦ پیت"),
    "loginPasswordHint": MessageLookupByLibrary.simpleMessage(
      "تێپەڕەوشەکەت بنوسە",
    ),
    "loginPasswordLabel": MessageLookupByLibrary.simpleMessage("تێپەڕەوشە"),
    "loginRequired": MessageLookupByLibrary.simpleMessage("پێویستە"),
    "loginSuccess": MessageLookupByLibrary.simpleMessage(
      "بەسەرکەوتوویی چوویتە ژوورەوە!",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("چونە دەرەوە"),
    "longitude": MessageLookupByLibrary.simpleMessage("درێژایی"),
    "my_orders_title": MessageLookupByLibrary.simpleMessage("داواکاریەکانم"),
    "networkError": MessageLookupByLibrary.simpleMessage(
      "هەڵەی ڕایەڵە — تکایە دووبارە هەوڵ بدە",
    ),
    "networkErrorTryAgain": MessageLookupByLibrary.simpleMessage(
      "هەڵەی ڕایەڵە — تکایە دووبارە هەوڵ بدە.",
    ),
    "newSearch": MessageLookupByLibrary.simpleMessage(
      "زاراوەیەک داخڵ بکە و گەڕان بکە",
    ),
    "noOrder": MessageLookupByLibrary.simpleMessage(
      "هیچ داواکاریەک نەدۆزرایەوە",
    ),
    "orderOn": MessageLookupByLibrary.simpleMessage("داواکاری لە"),
    "orderTab": MessageLookupByLibrary.simpleMessage("داواکاریەکان"),
    "order_number_prefix": MessageLookupByLibrary.simpleMessage("#ORD-"),
    "orders_empty_all": MessageLookupByLibrary.simpleMessage(
      "هیچ داواکاریەک نییە",
    ),
    "orders_empty_status": m2,
    "otpCodeLabel": MessageLookupByLibrary.simpleMessage("کۆدی ٦ ژمارەیی"),
    "otpConfirmPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی پشتڕاست بکەرەوە",
    ),
    "otpInvalidCode": MessageLookupByLibrary.simpleMessage(
      "کۆدی نادروست یان بەسەرچووە",
    ),
    "otpInvalidFormat": MessageLookupByLibrary.simpleMessage(
      "کۆدی ٦ ژمارەیی داخڵ بکە",
    ),
    "otpNewPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی نوێ",
    ),
    "otpPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی یەک ناگرێتەوە",
    ),
    "otpResend": MessageLookupByLibrary.simpleMessage("دوبارە ناردنەوە"),
    "otpResendIn": m3,
    "otpSubmit": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی ڕێست بکەرەوە",
    ),
    "otpTitle": MessageLookupByLibrary.simpleMessage(
      "ئەو کۆدە داخڵ بکە کە ئێمە ئیمەیڵمان بۆ ناردبوویت",
    ),
    "otpYouCanResend": MessageLookupByLibrary.simpleMessage(
      "دەتوانیت کۆدێکی نوێ بنێریتەوە",
    ),
    "pSignin": MessageLookupByLibrary.simpleMessage(
      "تکایە داخل ببە بۆ داوا کردن",
    ),
    "pSignin2": MessageLookupByLibrary.simpleMessage("داخل بە بۆ داواکاری"),
    "pack": MessageLookupByLibrary.simpleMessage("پاکەت"),
    "pack_order": MessageLookupByLibrary.simpleMessage("بە پاکەت داوا بکە"),
    "pack_size": MessageLookupByLibrary.simpleMessage("1 پاکەت"),
    "passwordUpdatedSuccess": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی نوێکرایەوە! ئێستا دەتوانیت بچیتە ژوورەوە.",
    ),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("Pشێوازی پارەدان"),
    "placeOrder": MessageLookupByLibrary.simpleMessage("داواکاری دابنێ"),
    "profileTab": MessageLookupByLibrary.simpleMessage("پڕۆفایلی"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("پەڕەی تایبەت"),
    "requiredField": MessageLookupByLibrary.simpleMessage("مەیدانی پێویست"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("پێداچوونەوە سەبەتە"),
    "save": MessageLookupByLibrary.simpleMessage("هەڵگرتن"),
    "seeMore": MessageLookupByLibrary.simpleMessage("بینینی زیاتر"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("ناردنی داواکاری"),
    "signUpAddressLabel": MessageLookupByLibrary.simpleMessage("ناونیشان"),
    "signUpButton": MessageLookupByLibrary.simpleMessage("تۆماربوون"),
    "signUpCta": MessageLookupByLibrary.simpleMessage(
      "هەژمارەت نیە؟ تۆمار ببە",
    ),
    "signUpEmailLabel": MessageLookupByLibrary.simpleMessage("ئیمەیل"),
    "signUpEnterAddress": MessageLookupByLibrary.simpleMessage(
      "ناونیشانت بنوسە",
    ),
    "signUpEnterEmail": MessageLookupByLibrary.simpleMessage("ئیمەیلت بنوسە"),
    "signUpEnterPhone": MessageLookupByLibrary.simpleMessage(
      "ژمارەی تەلەفۆنت بنوسە",
    ),
    "signUpEnterYourName": MessageLookupByLibrary.simpleMessage("ناوت بنوسە"),
    "signUpFullName": MessageLookupByLibrary.simpleMessage("ناوی تەواو"),
    "signUpInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "ئیمەیل دروست نیە",
    ),
    "signUpInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "ژمارەی تەلەفۆن نادروستە",
    ),
    "signUpLocationPicked": m4,
    "signUpNoLocationSelected": MessageLookupByLibrary.simpleMessage(
      "هیچ شوێنێک هەڵنەبژێردراوە",
    ),
    "signUpPasswordAllowedChars": MessageLookupByLibrary.simpleMessage(
      "تێپەڕەوشە تەنیا پیت، ژمارە و خاڵ (.) لەخۆ دەگرێت",
    ),
    "signUpPasswordLabel": MessageLookupByLibrary.simpleMessage("تێپەڕەوشە"),
    "signUpPasswordMin8": MessageLookupByLibrary.simpleMessage(
      "تێپەڕەوشە دەبێت کەمتر نەبێت لە ٨ پیت",
    ),
    "signUpPhoneLabel": MessageLookupByLibrary.simpleMessage("تەلەفۆن"),
    "signUpPickPhotoPrompt": MessageLookupByLibrary.simpleMessage(
      "تکایە وێنەیەک هەڵبژێرە",
    ),
    "signUpSelectLocationError": MessageLookupByLibrary.simpleMessage(
      "تکایە شوێنت دیاری بکە لەسەر نەخشە",
    ),
    "signUpSuccess": MessageLookupByLibrary.simpleMessage(
      "هەژمارت دروست کرا! تکایە بچۆ ژوورەوە.",
    ),
    "signUpTitle": MessageLookupByLibrary.simpleMessage("دروستکردنی هەژمار"),
    "singInOrder": MessageLookupByLibrary.simpleMessage(
      "داخل بوون بۆ بینینی داواکاریەکان",
    ),
    "slogan": MessageLookupByLibrary.simpleMessage(
      "دەربارەی بارڤین  بارڤین ئەپڵیکەیشنی دابینکردنی گشتگیرە کە تایبەتە بە پێشکەشکردنی بەرهەمی کوالیتی بەرز بە نرخێکی بێ ڕکابەر بۆ هەردوو لایەنی بازرگانی و بەکارهێنەری تاکەکەسی.  بارڤبین کۆمەڵێک پێداویستی سەرەکی دابین دەکات- لە قاوە و چا و پەنیر و تا دانەوێڵەش، زەیت و بەهارات و خواردنەوەکان و لەقوتوکراوەکان - دڵنیایی دەدات لەوەی کە هەموو کەسێک، جا چ بزنس بێت یان تاک، دەستیان بە بەرهەمی ئاست بەرز دەگات.  ئەرکی ئێمە پڕکردنەوەی بۆشایی نێوان نرخ و کوالیتی، و هاندانی  هەموو کڕیارەکانمان بۆ گەشەکردن.",
    ),
    "snackBasketEmpty": MessageLookupByLibrary.simpleMessage(
      "سەبەتەکەت بەتاڵە.",
    ),
    "snackNetworkError": MessageLookupByLibrary.simpleMessage(
      "هەڵەی تۆڕ — تکایە دووبارە هەوڵ بدە.",
    ),
    "snackOrderFail": MessageLookupByLibrary.simpleMessage(
      "نەتوانرا داواکاری بنێردرێت.",
    ),
    "snackOrderSuccess": MessageLookupByLibrary.simpleMessage(
      "داواکاری بە سەرکەوتوویی نێردرا!",
    ),
    "snackSignInToOrder": MessageLookupByLibrary.simpleMessage(
      "تکایە چونەژوورەوە بکە بۆ دانانی داواکاری.",
    ),
    "snackWhatsAppOpenFail": MessageLookupByLibrary.simpleMessage(
      "نەتوانرا واتساپ لەسەر ئەم ئامێرە بکەرەوە.",
    ),
    "status_delivered": MessageLookupByLibrary.simpleMessage("گەشتوو"),
    "status_pending": MessageLookupByLibrary.simpleMessage("لە چاوەڕوانیدا"),
    "subtotal": MessageLookupByLibrary.simpleMessage("نرخی پێش کۆتا"),
    "tDeals": MessageLookupByLibrary.simpleMessage("دیسکاونتەکانی ئەمرۆ"),
    "tab_delivered": MessageLookupByLibrary.simpleMessage("گەشتوو"),
    "tab_ordered": MessageLookupByLibrary.simpleMessage("داواکراو"),
    "tab_pending": MessageLookupByLibrary.simpleMessage("لە چاوەڕوانیدا"),
    "tap": MessageLookupByLibrary.simpleMessage(
      "بۆ زیادکردنی ناونیشانەکەت پەنجە بنێ",
    ),
    "tapToPickLocation": MessageLookupByLibrary.simpleMessage(
      "بۆ هەڵبژاردنی شوێن پەنجە بنێ",
    ),
    "tiktok": MessageLookupByLibrary.simpleMessage("تیک تۆک"),
    "total": MessageLookupByLibrary.simpleMessage("کۆتا"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("کۆی مەسرەف"),
    "total_label": MessageLookupByLibrary.simpleMessage("کۆ:"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("بنووسە بۆ گەڕان"),
    "unit": MessageLookupByLibrary.simpleMessage("یەکە"),
    "waAddress": MessageLookupByLibrary.simpleMessage("ناونیشان"),
    "waDelivery": MessageLookupByLibrary.simpleMessage("گەیاندن"),
    "waFree": MessageLookupByLibrary.simpleMessage("بەخۆڕایی"),
    "waHeader": MessageLookupByLibrary.simpleMessage(
      "🧾 Barvin – داواکارییەکی نوێ",
    ),
    "waName": MessageLookupByLibrary.simpleMessage("ناو"),
    "waPhone": MessageLookupByLibrary.simpleMessage("تەلەفۆن"),
    "waSubtotal": MessageLookupByLibrary.simpleMessage("کۆی سەرەتایی"),
    "waTotalUpper": MessageLookupByLibrary.simpleMessage("کۆی گشتی"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("بەخێربێیتەوە!"),
    "whatsAppTooltip": MessageLookupByLibrary.simpleMessage("ناردن بە واتساپ"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("داواکاریەکانت"),
  };
}
