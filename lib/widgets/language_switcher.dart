import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/localization_manager.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: context.locale.languageCode,
      items: LanguageManager.instance.supportedLocales.map((locale) {
        return DropdownMenuItem(
          value: locale.languageCode,
          child: Text(locale.languageCode == 'en' ? '🇺🇸 English' : '🇹🇷 Türkçe'),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          context.setLocale(Locale(newValue));
        }
      },
    );
  }
}