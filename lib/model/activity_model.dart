class Activity {
  int? id;
  DateTime startTime;
  DateTime endTime;
  double totalDistance;
  int elapsedTime;
  double averageSpeed;
  double? startPositionLat;
  double? startPositionLng;
  double? endPositionLat;
  double? endPositionLng;

  Activity({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.totalDistance,
    required this.elapsedTime,
    required this.averageSpeed,
    this.startPositionLat,
    this.startPositionLng,
    this.endPositionLat,
    this.endPositionLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'averageSpeed': averageSpeed,
      'startPositionLat': startPositionLat,
      'startPositionLng': startPositionLng,
      'endPositionLat': endPositionLat,
      'endPositionLng': endPositionLng,
    };
  }

  static Activity fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      totalDistance: map['totalDistance'],
      elapsedTime: map['elapsedTime'],
      averageSpeed: map['averageSpeed'],
      startPositionLat: map['startPositionLat'],
      startPositionLng: map['startPositionLng'],
      endPositionLat: map['endPositionLat'],
      endPositionLng: map['endPositionLng'],
    );
  }
}
