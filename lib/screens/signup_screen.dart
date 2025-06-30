import 'package:flutter/material.dart';
import 'package:map_tracker/screens/signin_screen.dart';
import 'package:map_tracker/screens/welcome_screen.dart' show WelcomeScreen;
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/widgets/custom_scaffold.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/utils/localizaton_constants.dart';

final locator = GetIt.instance;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final dbHelper = DatabaseHelper();

  Future<void> _handleSignUp() async {
    try {
      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      if (_formSignupKey.currentState!.validate() && agreePersonalData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.signUpInProgress.tr()),
          ),
        );

        try {
          await locator.get<AuthService>().signUp(
            context,
            name: firstName,
            surname: lastName,
            email: email,
            password: password,
          );
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.signUpError.tr(args: [e.toString()])),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.formValidationError.tr()),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.signUpError.tr(args: [e.toString()])),
          ),
        );
      }
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                border: Border(
                  top: BorderSide(
                    color: basarsoft_color,
                    width: 3.0,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        LocaleKeys.signUpTitle.tr(),
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: basarsoft_color,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LocaleKeys.firstNameRequired.tr();
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: LocaleKeys.firstNameLabel.tr(),
                                hintText: LocaleKeys.firstNameHint.tr(),
                                hintStyle: const TextStyle(
                                  color: Colors.black26,
                                ),
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
                          ),
                          const SizedBox(width: 20.0),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LocaleKeys.lastNameRequired.tr();
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: LocaleKeys.lastNameLabel.tr(),
                                hintText: LocaleKeys.lastNameHint.tr(),
                                hintStyle: const TextStyle(
                                  color: Colors.black26,
                                ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
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
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
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
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
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
                      Row(
                        children: [
                          Checkbox(
                            value: agreePersonalData,
                            onChanged: (bool? value) {
                              setState(() {
                                agreePersonalData = value!;
                              });
                            },
                            activeColor: basarsoft_color,
                          ),
                          Expanded(
                            child: Text(
                              LocaleKeys.agreePersonalData.tr(),
                              style: const TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: basarsoft_color,
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            LocaleKeys.signUpButton.tr(),
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.black,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            child: Text(
                              LocaleKeys.otherSignUpMethods.tr(),
                              style: const TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () async {
                              try {
                                var user = await locator.get<AuthService>().signInWithGoogle();
                                if (context.mounted && user != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(),
                                      settings: RouteSettings(arguments: user),
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocaleKeys.googleSignInFailed.tr()),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocaleKeys.googleSignInFailed.tr()),
                                    ),
                                  );
                                }
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
                          Text(
                            LocaleKeys.alreadyHaveAccount.tr(),
                            style: const TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Text(
                              LocaleKeys.signInLink.tr(),
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