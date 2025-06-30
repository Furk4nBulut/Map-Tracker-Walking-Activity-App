import 'package:flutter/material.dart';
import 'package:map_tracker/screens/signin_screen.dart';
import 'package:map_tracker/screens/signup_screen.dart';
import 'package:map_tracker/theme/theme.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/widgets/custom_scaffold.dart';
import 'package:map_tracker/widgets/language_switcher.dart';
import 'package:map_tracker/widgets/welcome_button.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/utils/localizaton_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  void navigateToSignIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  void navigateToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }

  void _toggleLanguage(BuildContext context) {
    if (context.locale == LocalizationConstants.EN_LOCALE) {
      context.setLocale(LocalizationConstants.TR_LOCALE);
    } else {
      context.setLocale(LocalizationConstants.EN_LOCALE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 40.0,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: basarsoft_color.withOpacity(0.3),
                            spreadRadius: 10,
                            blurRadius: 15,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 200.0,
                        color: Colors.white,
                        semanticLabel: 'Map Tracker Logo',
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: LocaleKeys.welcomeAppName.tr(),
                            style: const TextStyle(
                              fontSize: 50.0,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: basarsoft_color,
                                  offset: Offset(2, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: '\n${LocaleKeys.welcomeSubtitle.tr()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: basarsoft_color,
                                  offset: Offset(2, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const LanguageSwitcher(transparentBackground: true,showLabel: true,),


                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Expanded(
                    child: WelcomeButton(
                      buttonText: LocaleKeys.signInButton.tr(),
                      onTap: SignInScreen(),
                      color: Colors.transparent,
                      textColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: WelcomeButton(
                      buttonText: LocaleKeys.signUpButton.tr(),
                      onTap: const SignUpScreen(),
                      color: Colors.white,
                      textColor: basarsoft_color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}