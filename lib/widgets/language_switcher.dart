import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:country_flags/country_flags.dart';
import 'package:map_tracker/localization/localization_manager.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode = context.locale.languageCode;
    final isEnglish = currentLanguageCode == 'en';

    return GestureDetector(
      onTap: () => _showLanguageSelectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              isEnglish ? 'US' : 'TR',
              height: 16,
              width: 24,
              borderRadius: 4,
            ),
            const SizedBox(width: 6),
            Text(
              isEnglish ? 'English' : 'Türkçe',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
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
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: LanguageManager.instance.supportedLocales.map((locale) {
            final isEnglish = locale.languageCode == 'en';
            return ListTile(
              leading: CountryFlag.fromCountryCode(
                isEnglish ? 'US' : 'TR',
                height: 20,
                width: 28,
                borderRadius: 4,
              ),
              title: Text(isEnglish ? 'English' : 'Türkçe'),
              onTap: () {
                if (locale.languageCode != context.locale.languageCode) {
                  context.setLocale(locale);
                }
                Navigator.of(context).pop(); // Sheet kapat
              },
            );
          }).toList(),
        );
      },
    );
  }
}
