import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveActivity({
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
      // Save activity to Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('user').doc(user.uid).collection('activities').add({
          'startTime': startTime,
          'endTime': endTime,
          'totalDistance': totalDistance,
          'elapsedTime': elapsedTime,
          'averageSpeed': averageSpeed,
          'startPosition': startPosition != null
              ? GeoPoint(startPosition.latitude, startPosition.longitude)
              : null,
          'endPosition': endPosition != null
              ? GeoPoint(endPosition.latitude, endPosition.longitude)
              : null,
          'route': route.map((point) => GeoPoint(point.latitude, point.longitude)).toList(),
        });
      }

      // Save activity locally
      final db = DatabaseHelper();
      await db.insertActivity(Activity(
        startTime: startTime,
        endTime: endTime,
        totalDistance: totalDistance,
        elapsedTime: elapsedTime,
        averageSpeed: averageSpeed,
        startPositionLat: startPosition?.latitude,
        startPositionLng: startPosition?.longitude,
        endPositionLat: endPosition?.latitude,
        endPositionLng: endPosition?.longitude,
      ));

    } catch (e) {
      print('Aktivite kaydedilirken bir hata oluştu: $e');
      throw 'Aktivite kaydedilirken bir hata oluştu: $e';

    }
  }
}
