import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  SharedPreferences? _prefs;
  GoogleSignInAccount? _user;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Gerekirse AuthService'i de burada başlatabilirsin
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final user = await googleSignIn.signIn();
      if (user != null) {
        _user = user;
        await _prefs?.setString("email", user.email);
        notifyListeners();
      }
    } catch (e) {
      print("Google Sign-In error: $e");
    }
  }

  GoogleSignInAccount? get user => _user;

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    _user = null;
    await _prefs?.clear();
    notifyListeners();
  }
}
