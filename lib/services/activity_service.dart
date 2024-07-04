import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class ActivityService {
  final CollectionReference _activityCollection = FirebaseFirestore.instance.collection('activities');

  Future<void> saveActivity({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required LatLng? startPosition,
    required LatLng? endPosition,
  }) async {
    try {
      await _activityCollection.add({
        'startTime': startTime,
        'endTime': endTime,
        'totalDistance': totalDistance,
        'elapsedTime': elapsedTime,
        'startPosition': startPosition != null ? GeoPoint(startPosition.latitude, startPosition.longitude) : null,
        'endPosition': endPosition != null ? GeoPoint(endPosition.latitude, endPosition.longitude) : null,
      });
    } catch (e) {
      print('Error saving activity: $e');
      throw 'Aktivite kaydedilirken bir hata oluştu.';
    }
  }
}
