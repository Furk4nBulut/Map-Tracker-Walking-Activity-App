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

  // Aktiviteyi yerel veritabanına kaydetme
  Future<String?> saveActivityToLocal({
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
      String activityId = generateUniqueId();

      // Yerel veritabanına kaydet
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
      return activityId; // Aktivite ID'sini döndür
    } catch (e) {
      throw 'Yerel veritabanına kaydederken hata oluştu: $e';
    }
  }

  // Aktiviteyi Firestore'a kaydetme
  Future<void> saveActivityToFirestore({
    required String activityId,
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
      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Firestore'a kaydetme işlemi
        await _firestore.collection('user').doc(firebaseUser.uid).collection('activities').doc(activityId).set({
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
      print('Firestore\'a kaydederken hata oluştu: $e');
      throw 'Firestore\'a kaydederken hata oluştu: $e';
    }
  }

  String generateUniqueId() {
    var uuid = Uuid();
    String id = uuid.v4();
    return id;
  }

}
