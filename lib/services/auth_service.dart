import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/screens/welcome_screen.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/model/activity_model.dart';

class AuthService {
  final userCollection = FirebaseFirestore.instance.collection("user");
  final firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> signUp(BuildContext context, {required String name, required String surname, required String email, required String password}) async {
    try {
      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {

        await dbHelper.insertUser(LocalUser(email: email, firstName: name, lastName: surname, password: password));
        Fluttertoast.showToast(msg: "Yerele kaydedildi!", toastLength: Toast.LENGTH_LONG);

        await _registerUser(name: name, surname: surname, email: email, password: password);
        Fluttertoast.showToast(msg: "Online olarak kaydedildi!", toastLength: Toast.LENGTH_LONG);


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

          var firstName = email.split('@')[0];
          localUser = LocalUser(email: email, firstName: firstName, lastName: '', password: password);
          await dbHelper.insertUser(localUser);



          Fluttertoast.showToast(msg: "KUllanıcı yerele kaydedildi. Çevrimdışı giriş yapabilirsiniz.Tekrar giriş yapınız!", toastLength: Toast.LENGTH_LONG);
        } else {

          await dbHelper.updateUser(localUser);

          await _syncUserActivitiesFromFirestore(localUser);


          navigator.push(MaterialPageRoute(builder: (context) => HomePage()));

        }




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
    dbHelper.logout();
    await firebaseAuth.signOut();
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pop();
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

          LatLng? startPosition;
          if (data['startPosition'] != null) {
            startPosition = LatLng(data['startPosition']['latitude'], data['startPosition']['longitude']);
          }

          LatLng? endPosition;
          if (data['endPosition'] != null) {
            endPosition = LatLng(data['endPosition']['latitude'], data['endPosition']['longitude']);
          }

          List<LatLng> route = [];
          if (data['route'] != null) {
            for (var point in data['route']) {
              route.add(LatLng(point['latitude'], point['longitude']));
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
        Fluttertoast.showToast(msg: "Activities synchronized!", toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      print('An error occurred while syncing activities: $e');
      throw 'An error occurred while syncing activities: $e';
    }
  }



  Future<void> syncUserActivities(BuildContext context, LocalUser localUser) async {
    try {
      await _syncUserActivitiesFromFirestore(localUser);
      Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      print("Aktiviteleri senkronize ederken hata oluştu: $e");
      Fluttertoast.showToast(msg: "Aktiviteleri senkronize ederken hata oluştu: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

}
