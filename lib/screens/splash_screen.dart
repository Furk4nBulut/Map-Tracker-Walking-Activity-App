import 'package:flutter/material.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/screens/welcome_screen.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/services/local_db_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash screen delay
    final dbHelper = DatabaseHelper();
    bool isSessionValid = await dbHelper.isSessionValid();
    if (isSessionValid) {
      LocalUser? user = await dbHelper.getCurrentUser();
      if (user != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
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