import 'package:flutter_test/flutter_test.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/model/activity_model.dart';  // Activity sınıfının bulunduğu dosya
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:convert';

void main() {
  group('Activity Tests', () {
    late LocalUser user;
    late Activity activity;
    late List<LatLng> route;

    setUp(() {
      user = LocalUser(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        password: 'password123',
      );
      route = [
        LatLng(37.7749, -122.4194),
        LatLng(34.0522, -118.2437),
      ];
      activity = Activity(
        id: 'activity123',
        user: user,
        startTime: DateTime(2023, 10, 1, 10, 0),
        endTime: DateTime(2023, 10, 1, 12, 0),
        totalDistance: 10.5,
        elapsedTime: 7200,
        averageSpeed: 5.25,
        startPositionLat: 37.7749,
        startPositionLng: -122.4194,
        endPositionLat: 34.0522,
        endPositionLng: -118.2437,
        route: route,
      );
    });

    test('toMap should return a valid map', () {
      final map = activity.toMap();

      expect(map['id'], 'activity123');
      expect(map['userId'], 1);
      expect(map['startTime'], '2023-10-01T10:00:00.000');
      expect(map['endTime'], '2023-10-01T12:00:00.000');
      expect(map['totalDistance'], 10.5);
      expect(map['elapsedTime'], 7200);
      expect(map['averageSpeed'], 5.25);
      expect(map['startPositionLat'], 37.7749);
      expect(map['startPositionLng'], -122.4194);
      expect(map['endPositionLat'], 34.0522);
      expect(map['endPositionLng'], -118.2437);
      expect(map['route'], isNotNull);

      final decodedRoute = jsonDecode(map['route']!);
      expect(decodedRoute, isList);
      expect(decodedRoute.length, 2);
      expect(decodedRoute[0]['lat'], 37.7749);
      expect(decodedRoute[0]['lng'], -122.4194);
      expect(decodedRoute[1]['lat'], 34.0522);
      expect(decodedRoute[1]['lng'], -118.2437);
    });

    test('fromMap should create a valid Activity object', () {
      final map = activity.toMap();
      final newActivity = Activity.fromMap(map, user);

      expect(newActivity.id, 'activity123');
      expect(newActivity.user.id, 1);
      expect(newActivity.startTime, DateTime(2023, 10, 1, 10, 0));
      expect(newActivity.endTime, DateTime(2023, 10, 1, 12, 0));
      expect(newActivity.totalDistance, 10.5);
      expect(newActivity.elapsedTime, 7200);
      expect(newActivity.averageSpeed, 5.25);
      expect(newActivity.startPositionLat, 37.7749);
      expect(newActivity.startPositionLng, -122.4194);
      expect(newActivity.endPositionLat, 34.0522);
      expect(newActivity.endPositionLng, -118.2437);
      expect(newActivity.route, isNotNull);
      expect(newActivity.route!.length, 2);
      expect(newActivity.route![0].latitude, 37.7749);
      expect(newActivity.route![0].longitude, -122.4194);
      expect(newActivity.route![1].latitude, 34.0522);
      expect(newActivity.route![1].longitude, -118.2437);
    });

    test('fromMap should handle null route', () {
      final map = activity.toMap();
      map['route'] = null;  // route'u null yapalım
      final newActivity = Activity.fromMap(map, user);

      expect(newActivity.route, isNotNull);
      expect(newActivity.route!.isEmpty, isTrue);
    });
  });
}