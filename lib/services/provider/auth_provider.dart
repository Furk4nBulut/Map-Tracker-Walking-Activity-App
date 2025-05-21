import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;

  GoogleSignInAccount? get user => _user;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Burada otomatik giriş denemesi yapıyoruz
    try {
      final existingUser = await _googleSignIn.signInSilently();
      if (existingUser != null) {
        _user = existingUser;
        await _prefs?.setString("email", existingUser.email);
        notifyListeners();
      }
    } catch (e) {
      print("Silent sign-in error: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        _user = user;
        await _prefs?.setString("email", user.email);
        notifyListeners();
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    await _prefs?.clear();
    notifyListeners();
  }
}
