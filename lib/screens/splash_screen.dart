import 'package:flutter/material.dart';
import 'package:map_tracker/screens/welcome_screen.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = GetIt.instance<AuthService>();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      bool isLoggedIn = await _authService.isUserLoggedIn();
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        Fluttertoast.showToast(
          msg: "Oturum bulundu, ana sayfaya yönlendiriliyorsunuz.",
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Oturum kontrolü sırasında hata oluştu: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/cbg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}