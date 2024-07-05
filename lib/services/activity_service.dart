import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ActivityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveActivity({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    LatLng? startPosition,
    LatLng? endPosition,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user').doc(user.uid).collection('activities').add({
          'startTime': startTime,
          'endTime': endTime,
          'totalDistance': totalDistance,
          'elapsedTime': elapsedTime,
          'startPosition': startPosition != null ? GeoPoint(startPosition.latitude, startPosition.longitude) : null,
          'endPosition': endPosition != null ? GeoPoint(endPosition.latitude, endPosition.longitude) : null,
        });
      } else {
        throw 'User not logged in.';
      }
    } catch (e) {
      throw 'Error saving activity: $e';
    }
  }
}
