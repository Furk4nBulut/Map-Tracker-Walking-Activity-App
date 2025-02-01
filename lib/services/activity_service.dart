import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ActivityService {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Tüm dependency'leri constructor üzerinden alıyoruz
  ActivityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DatabaseHelper? dbHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _dbHelper = dbHelper ?? DatabaseHelper();

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
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final activityData = {
        'userId': user.id,
        'startTime': startTime.toIso8601String(), // DateTime'ı string olarak kaydediyoruz
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
        'route': route
            .map((latLng) => {'latitude': latLng.latitude, 'longitude': latLng.longitude})
            .toList(),
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