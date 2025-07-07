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
        Fluttertoast.showToast(
          msg: "İnternet bağlantınızı kontrol edin ve tekrar deneyin.",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        // Şifreyi hashle
        String hashedPassword = sha256.convert(utf8.encode(password)).toString();
        await dbHelper.insertUser(LocalUser(email: email, firstName: name, lastName: surname, password: hashedPassword));
        Fluttertoast.showToast(msg: "Yerele kaydedildi!", toastLength: Toast.LENGTH_LONG);

        await _registerUser(name: name, surname: surname, email: email); // Şifreyi Firestore'a gönderme
        Fluttertoast.showToast(msg: "Online olarak kaydedildi!", toastLength: Toast.LENGTH_LONG);

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
      Fluttertoast.showToast(msg: errorMessage, toastLength: Toast.LENGTH_LONG);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeScreen()));
    } catch (e) {
      Fluttertoast.showToast(msg: "Kayıt olurken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> signIn(BuildContext context, {required String email, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      // İnternet bağlantısını kontrol et
      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        Fluttertoast.showToast(
          msg: "İnternet bağlantınızı kontrol edin ve tekrar deneyin.",
          toastLength: Toast.LENGTH_LONG,
        );
        // Çevrimdışı giriş denemesi
        String hashedPassword = sha256.convert(utf8.encode(password)).toString();
        var localUser = await dbHelper.getUserByEmail(email);
        if (localUser != null && localUser.password == hashedPassword && await dbHelper.login(LocalUser(email: email, firstName: localUser.firstName, lastName: localUser.lastName, password: hashedPassword, id: localUser.id))) {
          navigator.pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
          Fluttertoast.showToast(
            msg: "Çevrimdışı giriş başarılı!",
            toastLength: Toast.LENGTH_LONG,
          );
          return;
        } else {
          Fluttertoast.showToast(
            msg: "Çevrimdışı giriş başarısız. Lütfen internet bağlantısıyla giriş yapın.",
            toastLength: Toast.LENGTH_LONG,
          );
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
          Fluttertoast.showToast(
            msg: "Kullanıcı yerele kaydedildi. Çevrimdışı giriş yapabilirsiniz.",
            toastLength: Toast.LENGTH_LONG,
          );
        } else {
          await dbHelper.updateUser(localUser);
          await _syncUserActivitiesFromFirestore(localUser);
          // Oturum bayrağını ayarla
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          navigator.pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
          Fluttertoast.showToast(msg: "Giriş başarılı!", toastLength: Toast.LENGTH_LONG);
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
      Fluttertoast.showToast(msg: errorMessage, toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      Fluttertoast.showToast(msg: "Giriş yaparken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // İnternet bağlantısını kontrol et
      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        Fluttertoast.showToast(
          msg: "İnternet bağlantınızı kontrol edin ve tekrar deneyin.",
          toastLength: Toast.LENGTH_LONG,
        );
        return null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Önceki oturumu temizle
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) {
        Fluttertoast.showToast(
          msg: "Google ile giriş iptal edildi.",
          toastLength: Toast.LENGTH_LONG,
        );
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
          Fluttertoast.showToast(
            msg: "Kullanıcı yerele kaydedildi.",
            toastLength: Toast.LENGTH_LONG,
          );
        }

        // Oturum bayrağını ayarla
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);



        // Başarılı giriş mesajı
        Fluttertoast.showToast(
          msg: "Google ile giriş başarılı!",
          toastLength: Toast.LENGTH_LONG,
        );

        // HomePage'e yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(),
            settings: RouteSettings(arguments: userCredential.user),
          ),
        );
        // Firestore'dan aktiviteleri senkronize et
        await _syncUserActivitiesFromFirestore(localUser);
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
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Google ile giriş sırasında bilinmeyen bir hata oluştu: $e",
        toastLength: Toast.LENGTH_LONG,
      );
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
      Fluttertoast.showToast(msg: "Çıkış yapıldı.", toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      Fluttertoast.showToast(msg: "Çıkış yaparken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
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
      Fluttertoast.showToast(msg: "Kullanıcı kaydı Firestore'a yapılırken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
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
            totalDistance: data['totalDistance'],
            elapsedTime: data['elapsedTime'],
            averageSpeed: data['averageSpeed'],
            startPositionLat: startPosition?.latitude,
            startPositionLng: startPosition?.longitude,
            endPositionLat: endPosition?.latitude,
            endPositionLng: endPosition?.longitude,
            route: route,
            id: activityId,
          );

          await dbHelper.insertActivity(activity);
        }
        Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      debugPrint('Aktiviteleri senkronize ederken hata oluştu: $e');
      throw 'Aktiviteleri senkronize ederken hata oluştu: $e';
    }
  }

  Future<void> syncUserActivities(BuildContext context, LocalUser localUser) async {
    try {
      await _syncUserActivitiesFromFirestore(localUser);
      Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      debugPrint("Aktiviteleri senkronize ederken hata oluştu: $e");
      Fluttertoast.showToast(msg: "Aktiviteleri senkronize ederken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
    }
  }
}