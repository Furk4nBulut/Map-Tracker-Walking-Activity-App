import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/model/user_model.dart';
import 'dart:convert';  // Add this import

class Activity {
  int? id;
  late DateTime startTime;
  late DateTime endTime;
  late double totalDistance;
  late int elapsedTime;
  late double averageSpeed;
  double? startPositionLat;
  double? startPositionLng;
  double? endPositionLat;
  double? endPositionLng;
  List<LatLng>? route;
  late LocalUser user;  // Integrate user from user_model.dart

  Activity({
    this.id,
    required this.user,
    required this.startTime,
    required this.endTime,
    required this.totalDistance,
    required this.elapsedTime,
    required this.averageSpeed,
    this.startPositionLat,
    this.startPositionLng,
    this.endPositionLat,
    this.endPositionLng,
    this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': user.id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'averageSpeed': averageSpeed,
      'startPositionLat': startPositionLat,
      'startPositionLng': startPositionLng,
      'endPositionLat': endPositionLat,
      'endPositionLng': endPositionLng,
      'route': route != null
          ? jsonEncode(route!.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList())
          : null,
    };
  }

  static Activity fromMap(Map<String, dynamic> map, LocalUser user) {
    return Activity(
      id: map['id'],
      user: user,
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      totalDistance: map['totalDistance'],
      elapsedTime: map['elapsedTime'],
      averageSpeed: map['averageSpeed'],
      startPositionLat: map['startPositionLat'],
      startPositionLng: map['startPositionLng'],
      endPositionLat: map['endPositionLat'],
      endPositionLng: map['endPositionLng'],
      route: map['route'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['route']))
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList()
          : [],
    );
  }
}
