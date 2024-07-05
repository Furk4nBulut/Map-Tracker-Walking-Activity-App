import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<void> saveActivity({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required LatLng? startPosition,
    required LatLng? endPosition,
    required List<LatLng> route,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
      await _db.collection('user').doc(user.uid).collection('activities').add({
        'startTime': startTime,
        'endTime': endTime,
        'totalDistance': totalDistance,
        'elapsedTime': elapsedTime,
        'startPosition': startPosition != null
            ? GeoPoint(startPosition.latitude, startPosition.longitude)
            : null,
        'endPosition': endPosition != null
            ? GeoPoint(endPosition.latitude, endPosition.longitude)
            : null,
        'route': route.map((point) => GeoPoint(point.latitude, point.longitude)).toList(),
      });
      }
    } catch (e) {
      throw 'Aktivite kaydedilirken bir hata oluştu: $e';
    }
  }
}
