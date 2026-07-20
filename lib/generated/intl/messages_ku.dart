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

  static String m0(status) =>
      "بارکردنی کاڵاکان سەرکەوتوو نەبوو (HTTP ${status}).";

  static String m1(error) => "هەڵە: ${error}";

  static String m2(count) => "بەردەستە: ${count}";

  static String m3(howMany) =>
      "${Intl.plural(howMany, zero: 'هیچ بابەتێک نییە', one: ' یەک دانە', other: '${howMany} چەندە')}";

  static String m4(error) => "هەڵە لە دیاریکردنی شوێن: ${error}";

  static String m5(status) => "هیچ ئۆردەرێک نییە";

  static String m6(seconds) => "دوبارە ناردنەوە لە {چرکە}s";

  static String m7(destination) => "کۆد نێردرا بۆ ${destination}.";

  static String m8(lat, lng) => "شوێن: (${lat}، ${lng})";

  static String m9(version) => "وەشانی داواکراو: ${version}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("دەربارەی ئێمە"),
    "addBasket": MessageLookupByLibrary.simpleMessage("زیاد بکە بۆ سەبەتە"),
    "addNewAddress": MessageLookupByLibrary.simpleMessage(
      "ناونیشانی نوێ زیاد بکە",
    ),
    "address": MessageLookupByLibrary.simpleMessage("ناونیشان"),
    "adsTitle": MessageLookupByLibrary.simpleMessage("ڕیکلامەکان"),
    "adsVisitLink": MessageLookupByLibrary.simpleMessage("سەردانی لینک"),
    "allDiscount": MessageLookupByLibrary.simpleMessage("هەموو دەسکاونتەکان"),
    "appName": MessageLookupByLibrary.simpleMessage("بارڤین"),
    "appTitle": MessageLookupByLibrary.simpleMessage("برڤین بەرنامە"),
    "backToLogin": MessageLookupByLibrary.simpleMessage(
      "گەڕانەوە بۆ چوونەژوورەوە",
    ),
    "basket": MessageLookupByLibrary.simpleMessage("سەتلی داواکاری"),
    "basketBadgeCustom": MessageLookupByLibrary.simpleMessage("سەبەتەی تایبەت"),
    "basketBadgePreset": MessageLookupByLibrary.simpleMessage("سەبەتەی خواردن"),
    "basketBuilderAddToCart": MessageLookupByLibrary.simpleMessage(
      "کاڵا هەڵبژێردراوەکان زیاد بکە بۆ سەبەتە",
    ),
    "basketBuilderAdding": MessageLookupByLibrary.simpleMessage("زیادکردن…"),
    "basketBuilderLoadError": MessageLookupByLibrary.simpleMessage(
      "نەتوانرا کۆگا باربکرێت.",
    ),
    "basketBuilderLoadFailed": m0,
    "basketBuilderPickAtLeastOne": MessageLookupByLibrary.simpleMessage(
      "لانیکەم یەک کاڵا هەڵبژێرە.",
    ),
    "basketBuilderSaveError": MessageLookupByLibrary.simpleMessage(
      "نەتوانرا سەبەتەکەت نوێ بکرێتەوە.",
    ),
    "basketBuilderSearchHint": MessageLookupByLibrary.simpleMessage(
      "گەڕان بۆ کاڵا…",
    ),
    "basketBuilderTitle": MessageLookupByLibrary.simpleMessage(
      "دروستکردنی سەبەتەی خۆراک",
    ),
    "basketEmpty": MessageLookupByLibrary.simpleMessage("سەتلەکە بەتالە"),
    "basketSectionCustom": MessageLookupByLibrary.simpleMessage(
      "سەبەتە تایبەتەکان",
    ),
    "basketSectionPreset": MessageLookupByLibrary.simpleMessage(
      "سەبەتەی خواردنی ئامادە",
    ),
    "basketSectionRegular": MessageLookupByLibrary.simpleMessage(
      "بابەتە باشتەکان",
    ),
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
    "createBasketCardBody": MessageLookupByLibrary.simpleMessage(
      "هەموو کاڵاکان لە کاتەلۆگەکەمان هەڵبژێرە و سەبەتەی تایبەتی خۆت بنێرە.",
    ),
    "createBasketCardTitle": MessageLookupByLibrary.simpleMessage(
      "سەبەتەی خۆت دروست بکە",
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
    "errorWithMessage": m1,
    "facebook": MessageLookupByLibrary.simpleMessage("فەیسبووک"),
    "featuredCategoriesTitle": MessageLookupByLibrary.simpleMessage(
      "هاوپۆلە پەرەنگاوەکان",
    ),
    "follow": MessageLookupByLibrary.simpleMessage("فۆڵۆومان بکەن"),
    "foodBasketCustomizeCta": MessageLookupByLibrary.simpleMessage(
      "گۆڕین و داواکاری",
    ),
    "foodBasketSectionTitle": MessageLookupByLibrary.simpleMessage(
      "سەبەتەکانی خواردن",
    ),
    "footerCredit": MessageLookupByLibrary.simpleMessage(
      "دیزاین کردنو پەرە پێدان لەلایەن یوئێستی ئەیجنسی",
    ),
    "forgotChooseMethod": MessageLookupByLibrary.simpleMessage(
      "دەتەوێت کۆدەکە چۆن وەربگریت؟",
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
    "handWorkSectionTitle": MessageLookupByLibrary.simpleMessage(
      "چاپەمەنی بارڤین",
    ),
    "handworkAvailableLabel": m2,
    "handworkContactButton": MessageLookupByLibrary.simpleMessage(
      "بۆ پرسیار پەیوەندی بکە",
    ),
    "handworkDesiredQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "ژمارەی داواکراو",
    ),
    "handworkNoDescription": MessageLookupByLibrary.simpleMessage(
      "هیچ وەسفێک دانەنراوە.",
    ),
    "hint": MessageLookupByLibrary.simpleMessage("بنووسە بۆ گەڕان"),
    "home": MessageLookupByLibrary.simpleMessage("ماڵەوە"),
    "instagram": MessageLookupByLibrary.simpleMessage("ئینستاگرام"),
    "item": MessageLookupByLibrary.simpleMessage("بابەت"),
    "itemsCount": m3,
    "language": MessageLookupByLibrary.simpleMessage("زمان"),
    "latitude": MessageLookupByLibrary.simpleMessage("پانی"),
    "locationConfirm": MessageLookupByLibrary.simpleMessage("شوێن پەسند بکە"),
    "locationErrorGeneric": m4,
    "locationFallbackHint": MessageLookupByLibrary.simpleMessage(
      "شوێنێکی بنەڕەتی پیشان دەدرێت — کرتە لەسەر نەخشە بکە بۆ دیاریکردنی شوێنی گەیاندن",
    ),
    "locationGettingYours": MessageLookupByLibrary.simpleMessage(
      "شوێنەکەت دیاری دەکرێت…",
    ),
    "locationPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "مۆڵەتی شوێن ڕەتکرایەوە",
    ),
    "locationPermissionDeniedForever": MessageLookupByLibrary.simpleMessage(
      "مۆڵەتی شوێن بە تەواوی ڕەتکرایەوە. لە ڕێکخستنەکان چالاکی بکە.",
    ),
    "locationPickerTitle": MessageLookupByLibrary.simpleMessage(
      "شوێنەکەت هەڵبژێرە",
    ),
    "locationServicesDisabled": MessageLookupByLibrary.simpleMessage(
      "خزمەتگوزاری شوێن ناچالاکە. تکایە GPS چالاک بکە.",
    ),
    "locationTapHint": MessageLookupByLibrary.simpleMessage(
      "کرتە لەسەر نەخشە بکە بۆ دیاریکردنی شوێنی گەیاندن",
    ),
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
    "orderHoursBody": MessageLookupByLibrary.simpleMessage(
      "داواکارییەکان لە نێوان ٨ی بەیانی و ١٠ی ئێوارە جێبەجێ دەکرێن. داواکارییەکانی دوای ١٠ی ئێوارە بۆ ڕۆژی داهاتوو لە ٨ی بەیانی دەستپێدەکەن.",
    ),
    "orderHoursHeading": MessageLookupByLibrary.simpleMessage(
      "کاتەکانی داواکاری",
    ),
    "orderOn": MessageLookupByLibrary.simpleMessage("داواکاری لە"),
    "orderTab": MessageLookupByLibrary.simpleMessage("داواکاریەکان"),
    "order_number_prefix": MessageLookupByLibrary.simpleMessage("#ORD-"),
    "orders_empty_all": MessageLookupByLibrary.simpleMessage(
      "هیچ داواکاریەک نییە",
    ),
    "orders_empty_status": m5,
    "otpCodeLabel": MessageLookupByLibrary.simpleMessage("کۆدی ٦ ژمارەیی"),
    "otpConfirmPasswordLabel": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی پشتڕاست بکەرەوە",
    ),
    "otpCreateAccountButton": MessageLookupByLibrary.simpleMessage(
      "هەژمار دروست بکە",
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
    "otpResendIn": m6,
    "otpResent": MessageLookupByLibrary.simpleMessage("کۆد دووبارە نێردرا."),
    "otpSentTo": m7,
    "otpSubmit": MessageLookupByLibrary.simpleMessage(
      "وشەی نهێنی ڕێست بکەرەوە",
    ),
    "otpTitle": MessageLookupByLibrary.simpleMessage(
      "ئەو کۆدە داخڵ بکە کە ئێمە ئیمەیڵمان بۆ ناردبوویت",
    ),
    "otpTitlePhone": MessageLookupByLibrary.simpleMessage(
      "کۆدی نێردراوی تەلەفۆن بنووسە",
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
    "presetBasketDescription": MessageLookupByLibrary.simpleMessage(
      "سەبەتەی ئامادە لەلایەن بارڤین.",
    ),
    "profileTab": MessageLookupByLibrary.simpleMessage("پڕۆفایلی"),
    "profileTitle": MessageLookupByLibrary.simpleMessage("پەڕەی تایبەت"),
    "qty": MessageLookupByLibrary.simpleMessage("بڕ"),
    "receiptBranchLabel": MessageLookupByLibrary.simpleMessage("شوێن/کۆگا:"),
    "receiptColCode": MessageLookupByLibrary.simpleMessage("کۆدی کاڵا"),
    "receiptColName": MessageLookupByLibrary.simpleMessage("ناوی کاڵا"),
    "receiptColNo": MessageLookupByLibrary.simpleMessage("ژ.ک"),
    "receiptColQty": MessageLookupByLibrary.simpleMessage("ژمارە"),
    "receiptColTotal": MessageLookupByLibrary.simpleMessage("کۆ"),
    "receiptColUnitPrice": MessageLookupByLibrary.simpleMessage("نرخی تاک"),
    "receiptCurrencyLabel": MessageLookupByLibrary.simpleMessage("دراو:"),
    "receiptCustomerNameLabel": MessageLookupByLibrary.simpleMessage(
      "ناوی کڕیار:",
    ),
    "receiptDateLabel": MessageLookupByLibrary.simpleMessage("بەروار:"),
    "receiptDeliveryFeeLabel": MessageLookupByLibrary.simpleMessage(
      "کرێی گەیاندن:",
    ),
    "receiptDiscountLabel": MessageLookupByLibrary.simpleMessage("داشکاندن:"),
    "receiptGrandTotalLabel": MessageLookupByLibrary.simpleMessage("کۆی گشتی:"),
    "receiptLaborFeeLabel": MessageLookupByLibrary.simpleMessage("کرێی کار:"),
    "receiptNumberLabel": MessageLookupByLibrary.simpleMessage("ژمارەی وەسڵ:"),
    "receiptSignatureLabel": MessageLookupByLibrary.simpleMessage(
      "واژۆی کڕیار:",
    ),
    "receiptSubtotalLabel": MessageLookupByLibrary.simpleMessage(
      "کۆی گشتی(سەرەتای):",
    ),
    "receiptTitle": MessageLookupByLibrary.simpleMessage("فرۆشتن"),
    "requiredField": MessageLookupByLibrary.simpleMessage("مەیدانی پێویست"),
    "reviewBasket": MessageLookupByLibrary.simpleMessage("پێداچوونەوە سەبەتە"),
    "save": MessageLookupByLibrary.simpleMessage("هەڵگرتن"),
    "seeMore": MessageLookupByLibrary.simpleMessage("بینینی زیاتر"),
    "sendOrder": MessageLookupByLibrary.simpleMessage("ناردنی داواکاری"),
    "signUpAddressLabel": MessageLookupByLibrary.simpleMessage("ناونیشان"),
    "signUpBack": MessageLookupByLibrary.simpleMessage("گەڕانەوە"),
    "signUpButton": MessageLookupByLibrary.simpleMessage("تۆماربوون"),
    "signUpContinue": MessageLookupByLibrary.simpleMessage("بەردەوامبوون"),
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
    "signUpLocationPicked": m8,
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
    "signUpSkipForNow": MessageLookupByLibrary.simpleMessage("ئێستا پەڕاندن"),
    "signUpSkipHint": MessageLookupByLibrary.simpleMessage(
      "دەتوانیت ناونیشانی گەیاندن هەر کاتێک لە پرۆفایلەکەت زیاد بکەیت.",
    ),
    "signUpStepAccount": MessageLookupByLibrary.simpleMessage(
      "هەنگاوی 1 لە 2 · زانیاری هەژمار",
    ),
    "signUpStepProfile": MessageLookupByLibrary.simpleMessage(
      "هەنگاوی 2 لە 2 · زانیاری گەیاندن",
    ),
    "signUpSuccess": MessageLookupByLibrary.simpleMessage(
      "بەخێربێیت بۆ بارڤین!",
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
    "tapToViewMore": MessageLookupByLibrary.simpleMessage(
      "کلیک بکە بۆ بینینی زیاتر",
    ),
    "tiktok": MessageLookupByLibrary.simpleMessage("تیک تۆک"),
    "total": MessageLookupByLibrary.simpleMessage("کۆتا"),
    "totalSpent": MessageLookupByLibrary.simpleMessage("کۆی مەسرەف"),
    "total_label": MessageLookupByLibrary.simpleMessage("کۆ:"),
    "typeSearch": MessageLookupByLibrary.simpleMessage("بنووسە بۆ گەڕان"),
    "unit": MessageLookupByLibrary.simpleMessage("یەکە"),
    "updateButton": MessageLookupByLibrary.simpleMessage("نوێکردنەوەی ئەپ"),
    "updateRequiredBody": MessageLookupByLibrary.simpleMessage(
      "وەشانی نوێی بارڤین بەردەستە. تکایە ئەپەکە نوێ بکەرەوە بۆ بەردەوام بوون.",
    ),
    "updateRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "پێویستی بە نوێکردنەوە",
    ),
    "updateStoreLinkHint": MessageLookupByLibrary.simpleMessage(
      "ئەگەر دوگمەکە کار نەکرد، فڕۆشگای ئەپەکەت بکەرەوە و \"Barvin\" بگەڕێ.",
    ),
    "updateVersionLabel": m9,
    "verificationEmailOption": MessageLookupByLibrary.simpleMessage(
      "کۆدی ئیمەیل",
    ),
    "verificationMethodLabel": MessageLookupByLibrary.simpleMessage(
      "شێوازی دڵنیابوونەوە",
    ),
    "verificationPhoneOption": MessageLookupByLibrary.simpleMessage(
      "کۆدی تەلەفۆن",
    ),
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
    "whatsappHelpBody": MessageLookupByLibrary.simpleMessage(
      "ئەگەر دوگمەی داواکاری کار نەکرد، دەتوانیت پەیوەندیی تیمی پارڤین بە واتساپ بکەیت.",
    ),
    "whatsappHelpCta": MessageLookupByLibrary.simpleMessage("یارمەتی واتساپ"),
    "yourOrders": MessageLookupByLibrary.simpleMessage("داواکاریەکانت"),
  };
}
