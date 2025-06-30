import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:country_flags/country_flags.dart';
import 'package:map_tracker/localization/localization_manager.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:map_tracker/utils/constants.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool transparentBackground; // Arkaplan şeffaf mı?
  final bool showLabel; // Bayrak altında yazı gözüksün mü?

  const LanguageSwitcher({
    super.key,
    this.transparentBackground = false,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentLang = context.locale.languageCode;

    String flagCode;
    switch (currentLang) {
      case 'tr':
        flagCode = 'TR';
        break;
      case 'de':
        flagCode = 'DE';
        break;
      case 'en':
      default:
        flagCode = 'US';
        break;
    }

    return GestureDetector(
      onTap: () => _showLanguageSelectionSheet(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: transparentBackground ? Colors.transparent : basarsoft_color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: transparentBackground
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              flagCode,
              height: 20,
              width: 30,
              borderRadius: 4,
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                LocaleKeys.languageToggle.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: LanguageManager.instance.supportedLocales.map((locale) {
            String flagCode;
            String languageText;

            switch (locale.languageCode) {
              case 'tr':
                flagCode = 'TR';
                languageText = LocaleKeys.languageTurkish.tr();
                break;
              case 'de':
                flagCode = 'DE';
                languageText = LocaleKeys.languageGerman.tr();
                break;
              case 'en':
              default:
                flagCode = 'US';
                languageText = LocaleKeys.languageEnglish.tr();
                break;
            }

            return ListTile(
              leading: CountryFlag.fromCountryCode(
                flagCode,
                height: 20,
                width: 28,
                borderRadius: 4,
              ),
              title: Text(languageText),
              onTap: () {
                if (locale != context.locale) {
                  context.setLocale(locale);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
