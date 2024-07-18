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
import 'package:map_tracker/services/local_db_service.dart'; // Assuming you have DatabaseHelper defined
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
          // User is not in local database, add them
          var firstName = email.split('@')[0];
          localUser = LocalUser(email: email, firstName: firstName, lastName: '', password: password);
          await dbHelper.insertUser(localUser);



          Fluttertoast.showToast(msg: "KUllanıcı yerele kaydedildi. Çevrimdışı giriş yapabilirsiniz.Tekrar giriş yapınız!", toastLength: Toast.LENGTH_LONG);
        } else {
          // User is in local database, update their details
          var firstName = email.split('@')[0];
          localUser.firstName = firstName;
          localUser.password = password;  // Update password in case it has changed
          await dbHelper.updateUser(localUser);
// Sync activities from Firestore to local database
          await _syncUserActivitiesFromFirestore(localUser);


          navigator.push(MaterialPageRoute(builder: (context) => HomePage()));

        }




      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    // Start the sign-in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    if (gUser == null) {
      // The user canceled the sign-in
      return null;
    }

    // Retrieve the authentication details
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // Create a credential object
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // Sign in the user with the credential
    final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

    // Retrieve user information
    final User? firebaseUser = userCredential.user;
    if (firebaseUser != null) {
      final String email = firebaseUser.email!;
      final String displayName = firebaseUser.displayName ?? '';
      String firstName =firebaseUser.displayName ?? '';
      String lastName = '';
      final String password = firebaseUser.uid;
      final String userid = firebaseUser.uid;
      print(email);
      print(displayName);
      print(firstName);
      print(lastName);
      print(password);
      print(password);
      print(password);
      print(password);
      print(firebaseUser.uid);
      print(userid);
      print(userid);
      print(userid);
      print(userid);

      // Save user information to Firestore
      await _registerGoogleUser(name: firstName, surname: lastName, email: email, password: password, id: userid);

      // Save user information to the local database
      LocalUser localUser = LocalUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password, // Password is not used in this case
      );

      await dbHelper.insertUser(localUser);
      signIn(context, email: email, password: password);


      // Sync activities from Firestore to local database
      await _syncUserActivitiesFromFirestore(localUser);
    }

    return firebaseUser;
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
  // register user for google with id field
  Future<void> _registerGoogleUser({required String name, required String surname, required String email, required String password, required String id}) async {
    await userCollection.doc(id).set({
      "id": id,
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



// syncuser to firestone
  Future<void> _syncUserActivitiesToFirestore(LocalUser localuser) async {
    try {
      User? firebaseUser = firebaseAuth.currentUser;
      LocalUser? localUser = await dbHelper.getUserByEmail(localuser.email);
      var userid = localUser?.id;
      if (firebaseUser != null) {
        List<Activity> activities = await dbHelper.getUserActivities(userid!);
        for (Activity activity in activities) {
          await firestore
              .collection('user')
              .doc(firebaseUser.uid)
              .collection('activities')
              .doc(activity.id)
              .set({
            'startTime': activity.startTime,
            'endTime': activity.endTime,
            'totalDistance': activity.totalDistance,
            'elapsedTime': activity.elapsedTime,
            'averageSpeed': activity.averageSpeed,
            'startPosition': {
              'latitude': activity.startPositionLat,
              'longitude': activity.startPositionLng,
            },
            'endPosition': {
              'latitude': activity.endPositionLat,
              'longitude': activity.endPositionLng,
            },
            'route': activity.route?.map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }).toList(),
          });
        }
        Fluttertoast.showToast(msg: "Aktiviteler senkronize edildi!", toastLength: Toast.LENGTH_LONG);
      }
    } catch (e)
    {
      print("Aktiviteleri senkronize ederken hata oluştu: $e");
      Fluttertoast.showToast(msg: "Buluta kaydedilemedi: $e", toastLength: Toast.LENGTH_LONG);
    }
  }


}
