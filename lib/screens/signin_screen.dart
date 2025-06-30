import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/screens/signup_screen.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/provider/auth_provider.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/widgets/custom_scaffold.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';

final locator = GetIt.instance;

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberPassword = true;

  AuthService get _authService => locator<AuthService>();
  AuthProvider get _authProvider => locator<AuthProvider>();

  DatabaseHelper dbHelper = DatabaseHelper();

  login() async {
    try {
      await _authService.signIn(
        context,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: LocaleKeys.signUpError.tr(args: [e.toString()]),
        toastLength: Toast.LENGTH_LONG,
      );
    }
    var response = await DatabaseHelper().login(
      LocalUser(
        firstName: '',
        lastName: '',
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );

    if (response == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: LocaleKeys.invalidCredentials.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(height: 10),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                border: Border.all(color: basarsoft_color, width: 2.0),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        LocaleKeys.signInTitle.tr(),
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: basarsoft_color,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocaleKeys.emailRequired.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: LocaleKeys.emailLabel.tr(),
                          hintText: LocaleKeys.emailHint.tr(),
                          hintStyle: const TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: basarsoft_color,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: basarsoft_color,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocaleKeys.passwordRequired.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: LocaleKeys.passwordLabel.tr(),
                          hintText: LocaleKeys.passwordHint.tr(),
                          hintStyle: const TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: basarsoft_color,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: basarsoft_color,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formSignInKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LocaleKeys.signInButton.tr()),
                                ),
                              );
                              login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: basarsoft_color,
                          ),
                          child: Text(
                            LocaleKeys.signInButton.tr(),
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            child: Text(
                              LocaleKeys.otherSignInMethods.tr(),
                              style: const TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              try {
                                var user = await locator.get<AuthService>().signInWithGoogle(context);
                                if (user != null) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                    settings: RouteSettings(arguments: user),
                                  ));
                                } else {
                                  Fluttertoast.showToast(
                                    msg: LocaleKeys.googleSignInFailed.tr(),
                                    toastLength: Toast.LENGTH_LONG,
                                  );
                                }
                              } catch (e) {
                                Fluttertoast.showToast(
                                  msg: LocaleKeys.googleSignInError.tr(args: [e.toString()]),
                                  toastLength: Toast.LENGTH_LONG,
                                );
                              }
                            },
                            child: Image.asset('assets/images/google.png'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(LocaleKeys.noAccount.tr()),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              LocaleKeys.signUpLink.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: basarsoft_color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}