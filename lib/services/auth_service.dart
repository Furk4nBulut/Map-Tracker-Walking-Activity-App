import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/screens/welcome_screen.dart';
import 'package:map_tracker/services/local_db_service.dart'; // Assuming you have DatabaseHelper defined
import 'package:map_tracker/model/user_model.dart';

class AuthService {
  final userCollection = FirebaseFirestore.instance.collection("user");
  final firebaseAuth = FirebaseAuth.instance;

  DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> signUp(BuildContext context, {required String name, required String surname, required String email, required String password}) async {
    try {
      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _registerUser(name: name, surname: surname, email: email, password: password);
        Fluttertoast.showToast(msg: "Online olarak kaydedildi!", toastLength: Toast.LENGTH_LONG);

        // Yerel veritabanına kullanıcıyı kaydet
        await dbHelper.insertUser(LocalUser(email: email, firstName: name, lastName: surname, password: password));
        Fluttertoast.showToast(msg: "Yerele kaydedildi!", toastLength: Toast.LENGTH_LONG);
      }
    } on FirebaseAuthException catch (e) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => WelcomeScreen()));
      Fluttertoast.showToast(msg: 'İlk kayıtta internet bağlantısı gereklidir! İnternet bağlantınızı kontrol edin!', toastLength: Toast.LENGTH_LONG);
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> signIn(BuildContext context, {required String email, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      final UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        var localUser = await dbHelper.getUserByEmail(email);
        if (localUser == null) {
          // Kullanıcı yerel veritabanında yoksa, ekle
          var firstName = email.split('@')[0];
          await dbHelper.insertUser(LocalUser(email: email, firstName: firstName, lastName: '', password: password));
          Fluttertoast.showToast(msg: "Yerele kaydedildi!", toastLength: Toast.LENGTH_LONG);
        } else {
          // Kullanıcı yerel veritabanında varsa, güncelle
          var firstName = email.split('@')[0];
          localUser.setFirstName = firstName;
          await dbHelper.updateUser(localUser);
          Fluttertoast.showToast(msg: "Yerel kullanıcı güncellendi!", toastLength: Toast.LENGTH_LONG);
        }
        navigator.push(MaterialPageRoute(builder: (context) => HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<User?> signInWithGoogle() async {
    // Oturum açma sürecini başlat
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    // Süreç içerisinden bilgileri al
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    // Kullanıcı nesnesi oluştur
    final credential = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);

    // Kullanıcı girişini sağla
    final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
    log(userCredential.user!.email.toString());
    return userCredential.user;
  }

  Future<void> signOut(BuildContext context) async {
    await firebaseAuth.signOut();
    Navigator.of(context).pop(); // Ana sayfaya dönmek için
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => WelcomeScreen()));
  }

  Future<void> _registerUser({required String name, required String surname, required String email, required String password}) async {
    await userCollection.doc().set({
      "email" : email,
      "name": name,
      "surname": surname,
      "password": password
    });
  }
}
