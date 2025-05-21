import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:map_tracker/screens/welcome_screen.dart'; // login/giriş ekranı
import 'package:map_tracker/screens/homepage.dart'; // giriş sonrası ana ekran
import '../../../services/provider/auth_provider.dart'; // AuthProvider'ı import et

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Burada 3 saniye bekleme yerine direkt login kontrolünü yapabiliriz.
    await Future.delayed(const Duration(seconds: 3));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Kullanıcı zaten login olmuş, anasayfaya git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Kullanıcı yok, login ekranına git
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
