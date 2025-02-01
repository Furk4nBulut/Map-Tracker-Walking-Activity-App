import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mocks
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late ActivityService activityService;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late LocalUser testUser;
  late DateTime startTime;
  late DateTime endTime;
  late LatLng startPosition;
  late LatLng endPosition;
  late List<LatLng> route;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    activityService = ActivityService();

    testUser = LocalUser(id: 1, firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com', password: 'password123');
    startTime = DateTime.now().subtract(Duration(hours: 1));
    endTime = DateTime.now();
    startPosition = LatLng(40.7128, -74.0060);
    endPosition = LatLng(40.730610, -73.935242);
    route = [startPosition, endPosition];
  });

  group('ActivityService', () {
    test('should save activity to local database', () async {
      // Arrange
      when(mockDatabaseHelper.insertActivity(any)).thenAnswer((_) async => null);

      // Act
      String? result = await activityService.saveActivityToLocal(
        user: testUser,
        startTime: startTime,
        endTime: endTime,
        totalDistance: 10.0,
        elapsedTime: 3600,
        averageSpeed: 10.0,
        startPosition: startPosition,
        endPosition: endPosition,
        route: route,
      );

      // Assert
      expect(result, isNotNull);
      verify(mockDatabaseHelper.insertActivity(any)).called(1);
    });

    test('should save activity to Firestore', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockFirebaseFirestore.collection(any).doc(any).collection(any).doc(any).set(any)).thenAnswer((_) async => null);

      // Act
      await activityService.saveActivityToFirestore(
        activityId: '1234',
        user: testUser,
        startTime: startTime,
        endTime: endTime,
        totalDistance: 10.0,
        elapsedTime: 3600,
        averageSpeed: 10.0,
        startPosition: startPosition,
        endPosition: endPosition,
        route: route,
      );

      // Assert
      verify(mockFirebaseFirestore.collection('user').doc('1234').collection('activities').doc('1234').set(any)).called(1);
    });
  });
}
