import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:map_tracker/utils/localizaton_constants.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'localization/localization_manager.dart';
import 'locator.dart';
import 'services/provider/auth_provider.dart';
import 'utils/constants.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'localization/locale_keys.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();
  setupLocator();
  runApp(
    EasyLocalization(
      supportedLocales: LanguageManager.instance.supportedLocales,
      path: LocalizationConstants.LANGUAGE_ASSETS_PATH,
      fallbackLocale: LocalizationConstants.EN_LOCALE,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (context) => locator.get<AuthProvider>(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: LocaleKeys.appTitle.tr(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: kPrimaryColor,
          fontFamily: 'Montserrat',
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashScreen(),
    );
  }
}