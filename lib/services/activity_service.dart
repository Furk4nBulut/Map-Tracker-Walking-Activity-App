import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';

class ActivityService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
      await _dbHelper.insertActivity(Activity(
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
    } catch (e) {
      print('An error occurred while saving the activity: $e');
      throw 'An error occurred while saving the activity: $e';
    }
  }
}
