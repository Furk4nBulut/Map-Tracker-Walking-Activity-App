import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ActivityService {
  final CollectionReference _activitiesCollection = FirebaseFirestore.instance.collection('activities');

  Future<void> saveActivity({
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required Position startPosition,
    required Position endPosition,
  }) async {
    try {
      await _activitiesCollection.add({
        'startTime': startTime,
        'endTime': endTime,
        'totalDistance': totalDistance,
        'elapsedTime': elapsedTime,
        'startLatitude': startPosition.latitude,
        'startLongitude': startPosition.longitude,
        'endLatitude': endPosition.latitude,
        'endLongitude': endPosition.longitude,
      });
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  Future<List<DocumentSnapshot>> getActivities() async {
    try {
      QuerySnapshot querySnapshot = await _activitiesCollection.get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Failed to get activities: $e');
    }
  }
}
