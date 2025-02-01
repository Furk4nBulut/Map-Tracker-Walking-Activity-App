import 'package:flutter_test/flutter_test.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Mock Sınıfları
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockUser extends Mock implements User {}
class MockFirestoreCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockFirestoreDocument extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late ActivityService activityService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockDatabaseHelper mockDbHelper;

  final testUser = LocalUser(
    id: 1,
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    password: 'password',
  );

  final testStartTime = DateTime.now();
  final testEndTime = testStartTime.add(const Duration(minutes: 30));
  const testTotalDistance = 5.0;
  const testElapsedTime = 1800;
  const testAverageSpeed = 10.0;
  final testStartPosition = const LatLng(40.7128, -74.0060);
  final testEndPosition = const LatLng(40.730610, -73.935242);
  final testRoute = [
    const LatLng(40.7128, -74.0060),
    const LatLng(40.7188, -74.0020),
    const LatLng(40.7200, -74.0000),
  ];

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockDbHelper = MockDatabaseHelper();

    activityService = ActivityService(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('ActivityService Tests', () {
    test('saveActivityToLocal should save activity and return ID', () async {
      // Arrange
      final activity = Activity(
        id: 'test-id',
        user: testUser,
        startTime: testStartTime,
        endTime: testEndTime,
        totalDistance: testTotalDistance,
        elapsedTime: testElapsedTime,
        averageSpeed: testAverageSpeed,
        startPositionLat: testStartPosition.latitude,
        startPositionLng: testStartPosition.longitude,
        endPositionLat: testEndPosition.latitude,
        endPositionLng: testEndPosition.longitude,
        route: testRoute,
      );

      when(mockDbHelper.insertActivity(activity)).thenAnswer((_) async => 'test-id');

      // Act
      final result = await activityService.saveActivityToLocal(
        user: testUser,
        startTime: testStartTime,
        endTime: testEndTime,
        totalDistance: testTotalDistance,
        elapsedTime: testElapsedTime,
        averageSpeed: testAverageSpeed,
        startPosition: testStartPosition,
        endPosition: testEndPosition,
        route: testRoute,
      );

      // Assert
      expect(result, 'test-id');
      verify(mockDbHelper.insertActivity(activity)).called(1);
    });

    test('saveActivityToFirestore should save activity data', () async {
      // Arrange
      final activity = Activity(
        id: 'test-id',
        user: testUser,
        startTime: testStartTime,
        endTime: testEndTime,
        totalDistance: testTotalDistance,
        elapsedTime: testElapsedTime,
        averageSpeed: testAverageSpeed,
        startPositionLat: testStartPosition.latitude,
        startPositionLng: testStartPosition.longitude,
        endPositionLat: testEndPosition.latitude,
        endPositionLng: testEndPosition.longitude,
        route: testRoute,
      );

      final mockUser = MockUser();
      final mockCollection = MockFirestoreCollection();
      final mockDoc = MockFirestoreDocument();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-uid');
      when(mockFirestore.collection('user')).thenReturn(mockCollection);
      when(mockCollection.doc('test-uid')).thenReturn(mockDoc);
      when(mockDoc.collection('activities')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDoc);

      // Act
      await activityService.saveActivityToFirestore(
        activityId: 'test-id',
        user: testUser,
        startTime: testStartTime,
        endTime: testEndTime,
        totalDistance: testTotalDistance,
        elapsedTime: testElapsedTime,
        averageSpeed: testAverageSpeed,
        startPosition: testStartPosition,
        endPosition: testEndPosition,
        route: testRoute,
      );

      // Assert
      verify(mockDoc.set({
        'userId': testUser.id,
        'startTime': testStartTime.toIso8601String(),
        'endTime': testEndTime.toIso8601String(),
        'totalDistance': testTotalDistance,
        'elapsedTime': testElapsedTime,
        'averageSpeed': testAverageSpeed,
        'startPosition': {
          'latitude': testStartPosition.latitude,
          'longitude': testStartPosition.longitude
        },
        'endPosition': {
          'latitude': testEndPosition.latitude,
          'longitude': testEndPosition.longitude
        },
        'route': testRoute
            .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
            .toList(),
      })).called(1);
    });

    test('generateUniqueId should return valid UUID', () {
      // Act
      final result = activityService.generateUniqueId();

      // Assert
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(20));
    });
  });
}
