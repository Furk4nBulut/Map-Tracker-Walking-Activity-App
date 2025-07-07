import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/screens/welcome_screen.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/constants.dart';

class AuthService {
  final userCollection = FirebaseFirestore.instance.collection("user");
  final firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DatabaseHelper dbHelper = DatabaseHelper();

  // İnternet bağlantısını kontrol eden yardımcı fonksiyon
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Kullanıcının oturum durumunu kontrol et
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn && firebaseAuth.currentUser != null;
  }

  Future<void> signUp(BuildContext context, {required String name, required String surname, required String email, required String password}) async {
    try {
      // İnternet bağlantısını kontrol et
      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        showErrorSnackbar(context, "İnternet bağlantınızı kontrol edin ve tekrar deneyin.");
        return;
      }

      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        // Şifreyi hashle
        String hashedPassword = sha256.convert(utf8.encode(password)).toString();
        await dbHelper.insertUser(LocalUser(email: email, firstName: name, lastName: surname, password: hashedPassword));
        showErrorSnackbar(context, "Kullanıcı başarıyla kaydedildi.");

        await _registerUser(name: name, surname: surname, email: email); // Şifreyi Firestore'a gönderme
        showErrorSnackbar(context, "Kullanıcı online olarak kaydedildi.");

        // Oturum bayrağını ayarla
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Bu e-posta adresi zaten kullanılıyor.";
          break;
        case 'invalid-email':
          errorMessage = "Geçersiz e-posta adresi.";
          break;
        case 'weak-password':
          errorMessage = "Şifre çok zayıf. Daha güçlü bir şifre girin.";
          break;
        default:
          errorMessage = e.message ?? "Kayıt olurken hata oluştu.";
      }
      showErrorSnackbar(context, errorMessage, debugMessage: e.toString());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeScreen()));
    } catch (e) {
      showErrorSnackbar(context, "Kayıt olurken bir hata oluştu. Lütfen tekrar deneyin.", debugMessage: e.toString());
    }
  }

  Future<void> signIn(BuildContext context, {required String email, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      // İnternet bağlantısını kontrol et
      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        showErrorSnackbar(context, "İnternet bağlantınızı kontrol edin ve tekrar deneyin.");
        // Çevrimdışı giriş denemesi
        String hashedPassword = sha256.convert(utf8.encode(password)).toString();
        var localUser = await dbHelper.getUserByEmail(email);
        if (localUser != null && localUser.password == hashedPassword && await dbHelper.login(LocalUser(email: email, firstName: localUser.firstName, lastName: localUser.lastName, password: hashedPassword, id: localUser.id))) {
          navigator.pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
          showErrorSnackbar(context, "Çevrimdışı giriş başarılı.");
          return;
        } else {
          showErrorSnackbar(context, "Çevrimdışı giriş başarısız. Lütfen internet bağlantısıyla giriş yapın.");
          return;
        }
      }

      final UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        String hashedPassword = sha256.convert(utf8.encode(password)).toString();
        var localUser = await dbHelper.getUserByEmail(email);
        if (localUser == null) {
          var firstName = email.split('@')[0];
          localUser = LocalUser(email: email, firstName: firstName, lastName: '', password: hashedPassword);
          await dbHelper.insertUser(localUser);
          showErrorSnackbar(context, "Kullanıcı yerele kaydedildi. Çevrimdışı giriş yapabilirsiniz.");
        } else {
          await dbHelper.updateUser(localUser);
          await _syncUserActivitiesFromFirestore(localUser);
          // Oturum bayrağını ayarla
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          navigator.pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
          showErrorSnackbar(context, "Giriş başarılı.");
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Kullanıcı bulunamadı. Lütfen kayıt olun.";
          break;
        case 'wrong-password':
          errorMessage = "Yanlış şifre girdiniz.";
          break;
        case 'invalid-email':
          errorMessage = "Geçersiz e-posta adresi.";
          break;
        default:
          errorMessage = e.message ?? "Giriş yaparken hata oluştu.";
      }
      showErrorSnackbar(context, errorMessage, debugMessage: e.toString());
    } catch (e) {
      showErrorSnackbar(context, "Giriş yaparken bir hata oluştu. Lütfen tekrar deneyin.", debugMessage: e.toString());
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // İnternet bağlantısını kontrol et
      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        showErrorSnackbar(context, "İnternet bağlantınızı kontrol edin ve tekrar deneyin.");
        return null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Önceki oturumu temizle
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) {
        showErrorSnackbar(context, "Google ile giriş iptal edildi.");
        return null; // Kullanıcı girişi iptal etti
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Yerel veritabanına kullanıcıyı kaydet
        var localUser = await dbHelper.getUserByEmail(userCredential.user!.email!);
        if (localUser == null) {
          localUser = LocalUser(
            email: userCredential.user!.email!,
            firstName: userCredential.user!.displayName?.split(' ').first ?? '',
            lastName: userCredential.user!.displayName?.split(' ').last ?? '',
            password: '', // Google Sign-In için şifre yok
          );
          await dbHelper.insertUser(localUser);
          showErrorSnackbar(context, "Kullanıcı yerele kaydedildi.");
        }

        // Oturum bayrağını ayarla
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Başarılı giriş mesajı
        showErrorSnackbar(context, "Google ile giriş başarılı.");

        // HomePage'e yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(),
            settings: RouteSettings(arguments: userCredential.user),
          ),
        );
        log(userCredential.user!.email.toString());
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = "Bu e-posta başka bir giriş yöntemiyle kullanılıyor.";
          break;
        case 'invalid-credential':
          errorMessage = "Geçersiz kimlik bilgileri. Lütfen tekrar deneyin.";
          break;
        case 'user-disabled':
          errorMessage = "Bu hesap devre dışı bırakılmış.";
          break;
        default:
          errorMessage = "Google ile giriş başarısız: ${e.message}";
      }
      showErrorSnackbar(context, errorMessage, debugMessage: e.toString());
      return null;
    } catch (e) {
      showErrorSnackbar(context, "Google ile giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.", debugMessage: e.toString());
      return null;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      // Oturum bayrağını temizle
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await dbHelper.logout();
      await firebaseAuth.signOut();
      await GoogleSignIn().signOut(); // Google Sign-In oturumunu temizle

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
            (Route<dynamic> route) => false,
      );
      showErrorSnackbar(context, "Çıkış yapıldı.");
    } catch (e) {
      showErrorSnackbar(context, "Çıkış yaparken bir hata oluştu. Lütfen tekrar deneyin.", debugMessage: e.toString());
    }
  }

  Future<void> _registerUser({required String name, required String surname, required String email}) async {
    try {
      await userCollection.doc(firebaseAuth.currentUser!.uid).set({
        "email": email,
        "name": name,
        "surname": surname,
      });
    } catch (e) {
      debugPrint("Kullanıcı kaydı Firestore'a yapılırken hata oluştu: $e");
      throw Exception("Kullanıcı kaydı Firestore'a yapılırken hata oluştu.");
    }
  }

  Future<void> _syncUserActivitiesFromFirestore(LocalUser localUser) async {
    try {
      User? firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser != null) {
        QuerySnapshot activitySnapshot = await firestore
            .collection('user')
            .doc(firebaseUser.uid)
            .collection('activities')
            .get();

        for (var doc in activitySnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String activityId = doc.id;
          Fluttertoast.showToast(msg: "Kullanıcı bilgileri güncelleniyor!", toastLength: Toast.LENGTH_LONG);

          osm.GeoPoint? startPosition;
          if (data['startPosition'] != null) {
            startPosition = osm.GeoPoint(
              latitude: data['startPosition']['latitude'],
              longitude: data['startPosition']['longitude'],
            );
          }

          osm.GeoPoint? endPosition;
          if (data['endPosition'] != null) {
            endPosition = osm.GeoPoint(
              latitude: data['endPosition']['latitude'],
              longitude: data['endPosition']['longitude'],
            );
          }

          List<osm.GeoPoint> route = [];
          if (data['route'] != null) {
            for (var point in data['route']) {
              route.add(osm.GeoPoint(
                latitude: point['latitude'],
                longitude: point['longitude'],
              ));
            }
          }

          Activity activity = Activity(
            user: localUser,
            startTime: (data['startTime'] as Timestamp).toDate(),
            endTime: (data['endTime'] as Timestamp).toDate(),
            totalDistance: (data['totalDistance'] ?? 0.0).toDouble(),
            elapsedTime: (data['elapsedTime'] ?? 0).toInt(),
            averageSpeed: (data['averageSpeed'] ?? 0.0).toDouble(),
            startPositionLat: data['startPosition']?['latitude'],
            startPositionLng: data['startPosition']?['longitude'],
            endPositionLat: data['endPosition']?['latitude'],
            endPositionLng: data['endPosition']?['longitude'],
            route: route,
            id: activityId,
          );

          await dbHelper.insertActivity(activity);
        }
        Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      debugPrint('Aktiviteleri senkronize ederken hata oluştu: $e');
      throw Exception('Aktiviteleri senkronize ederken hata oluştu.');
    }
  }

  Future<void> syncUserActivities(BuildContext context, LocalUser localUser) async {
    try {
      await _syncUserActivitiesFromFirestore(localUser);
      Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      debugPrint("Aktiviteleri senkronize ederken hata oluştu: $e");
      showErrorSnackbar(context, "Aktiviteleri senkronize ederken bir hata oluştu.", debugMessage: e.toString());
    }
  }
}