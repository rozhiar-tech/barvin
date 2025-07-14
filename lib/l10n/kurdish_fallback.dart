// lib/l10n/kurdish_fallback.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

/// If the app locale is 'ku', load English MaterialLocalizations instead.
class KurdishMaterialFallback
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KurdishMaterialFallback();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}

/// If the app locale is 'ku', load English CupertinoLocalizations instead.
class KurdishCupertinoFallback
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KurdishCupertinoFallback();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}
