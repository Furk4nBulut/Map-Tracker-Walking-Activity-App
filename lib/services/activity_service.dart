import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;

class ActivityService {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DatabaseHelper? dbHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _dbHelper = dbHelper ?? DatabaseHelper();

  Future<String?> saveActivityToLocal({
    required LocalUser user,
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required double averageSpeed,
    required osm.GeoPoint? startPosition,
    required osm.GeoPoint? endPosition,
    required List<osm.GeoPoint> route,
  }) async {
    try {
      String activityId = generateUniqueId();

      final activity = Activity(
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
      );

      await _dbHelper.insertActivity(activity);
      return activityId;
    } catch (e) {
      throw Exception('Yerel veritabanına kaydederken hata oluştu: $e');
    }
  }

  Future<void> saveActivityToFirestore({
    required String activityId,
    required LocalUser user,
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistance,
    required int elapsedTime,
    required double averageSpeed,
    required osm.GeoPoint? startPosition,
    required osm.GeoPoint? endPosition,
    required List<osm.GeoPoint> route,
  }) async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final activityData = {
        'userId': user.id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalDistance': totalDistance,
        'elapsedTime': elapsedTime,
        'averageSpeed': averageSpeed,
        'startPosition': startPosition != null
            ? {'latitude': startPosition.latitude, 'longitude': startPosition.longitude}
            : null,
        'endPosition': endPosition != null
            ? {'latitude': endPosition.latitude, 'longitude': endPosition.longitude}
            : null,
        'route': route.map((geoPoint) => {
          'latitude': geoPoint.latitude,
          'longitude': geoPoint.longitude
        }).toList(),
      };

      await _firestore
          .collection('user')
          .doc(firebaseUser.uid)
          .collection('activities')
          .doc(activityId)
          .set(activityData);
    } catch (e) {
      throw Exception('Firestore\'a kaydederken hata oluştu: $e');
    }
  }

  String generateUniqueId() {
    final uuid = Uuid();
    return uuid.v4();
  }
}