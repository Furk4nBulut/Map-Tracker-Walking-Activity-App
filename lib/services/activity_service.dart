import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ActivityService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveActivity({
    required LocalUser user,
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required double averageSpeed,
    required LatLng? startPosition,
    required LatLng? endPosition,
    required List<LatLng> route,
  }) async {
    try {
      // Save activity locally
      String activityId = generateUniqueId();
      await _dbHelper.insertActivity(Activity(
        id: activityId,
        user: user,
        startTime: startTime,
        endTime: endTime,
        totalDistance: totalDistance,
        elapsedTime: elapsedTime,
        averageSpeed: averageSpeed,
        startPositionLat: startPosition?.latitude,
        startPositionLng: startPosition?.longitude,
        endPositionLat: endPosition?.latitude,
        endPositionLng: endPosition?.longitude,
        route: route,
      ));

      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? firebaseuser = _auth.currentUser;
      if (firebaseuser != null) {
        // Save activity to Firestore
        await _firestore.collection('user').doc(firebaseuser.uid).collection('activities').add({
          'id': activityId,
          'userId': user.id,
          'startTime': startTime,
          'endTime': endTime,
          'totalDistance': totalDistance,
          'elapsedTime': elapsedTime,
          'averageSpeed': averageSpeed,
          'startPosition': startPosition != null
              ? {'latitude': startPosition.latitude, 'longitude': startPosition.longitude}
              : null,
          'endPosition': endPosition != null
              ? {'latitude': endPosition.latitude, 'longitude': endPosition.longitude}
              : null,
          'route': route.map((latLng) => {'latitude': latLng.latitude, 'longitude': latLng.longitude}).toList(),
        });
      }
    } catch (e) {
      print('An error occurred while saving the activity: $e');
      throw 'An error occurred while saving the activity: $e';
    }
  }

  // Basit bir benzersiz ID oluşturma işlevi
  String generateUniqueId() {
    var uuid = Uuid();
    return uuid.v4();
  }
}
