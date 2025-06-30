import 'package:flutter/material.dart';

class LocalizationConstants {
  static const LANGUAGE_ASSETS_PATH = "assets/localization";

  static const EN_LOCALE = Locale("en", "US");
  static const TR_LOCALE = Locale("tr", "TR");
  static const DE_LOCALE = Locale("de", "DE");

  static const SUPPORTED_LOCALE = [
    EN_LOCALE,
    TR_LOCALE,
    DE_LOCALE,
  ];
}