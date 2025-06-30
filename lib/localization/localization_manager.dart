import 'package:flutter/material.dart';
//flutter pub run easy_localization:generate -o lib/localization -f keys -o locale_keys.g.dart -S assets/localization -O lib/localization/
class LanguageManager {

  LanguageManager._init();
  static LanguageManager? _instance;
  static LanguageManager get instance {
    _instance ??= LanguageManager._init();
    return _instance!;
  }

  final enLocale = const Locale('en', 'US');
  final trLocale = const Locale('tr', 'TR');

  List<Locale> get supportedLocales => [enLocale, trLocale];
}