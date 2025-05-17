import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import '../model/user_model.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  Future<Activity?> _fetchActivity() async {
    final localActivity = await DatabaseHelper().getActivityById(activityId);
    if (localActivity != null) {
      return localActivity;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(firebaseUser.uid)
        .collection('activities')
        .doc(activityId)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;
    final routeData = data['route'] as List<dynamic>?;
    final route = routeData != null
        ? routeData
        .map((point) => osm.GeoPoint(
      latitude: point['lat'] as double,
      longitude: point['lng'] as double,
    ))
        .toList()
        : <osm.GeoPoint>[];

    return Activity(
      id: doc.id,
      user: LocalUser(
        id: 0,
        firstName: '',
        lastName: '',
        email: '',
        password: '',
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalDistance: data['totalDistance'],
      elapsedTime: data['elapsedTime'],
      averageSpeed: data['averageSpeed'],
      startPositionLat: data['startPositionLat'],
      startPositionLng: data['startPositionLng'],
      endPositionLat: data['endPositionLat'],
      endPositionLng: data['endPositionLng'],
      route: route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Activity?>(
      future: _fetchActivity(),
      builder: (context, AsyncSnapshot<Activity?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
            body: const Center(
              child: Text('Aktivite bulunamadı.'),
            ),
          );
        }

        Activity activity = snapshot.data!;
        DateTime startTime = activity.startTime;
        DateTime? endTime = activity.endTime;
        double totalDistance = activity.totalDistance ?? 0.0;
        List<osm.GeoPoint> route = activity.route ?? [];

        osm.MapController mapController = osm.MapController(
          initPosition: route.isNotEmpty
              ? route.first
              : osm.GeoPoint(latitude: 0, longitude: 0),
        );

        return Scaffold(
          appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: osm.OSMFlutter(
                  controller: mapController,
                  osmOption: const osm.OSMOption(),
                  mapIsLoading: const Center(child: CircularProgressIndicator()),
                  onMapIsReady: (isReady) async {
                    if (isReady && route.isNotEmpty) {
                      await mapController.setZoom(zoomLevel: 15);
                      if (route.length > 1) {
                        await mapController.drawRoad(
                          route.first,
                          route.last,
                          roadType: osm.RoadType.foot,
                          roadOption: const osm.RoadOption(
                            roadColor: Colors.blue,
                            roadWidth: 5,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: const Icon(Icons.timer, color: Colors.blue),
                                title: const Text('Başlangıç Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm').format(startTime)),
                              ),
                            ),
                            if (endTime != null)
                              Expanded(
                                child: ListTile(
                                  leading: const Icon(Icons.timer_off, color: Colors.red),
                                  title: const Text('Bitiş Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                  subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm').format(endTime)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: const Icon(Icons.directions_walk, color: Colors.green),
                                title: const Text('Toplam Mesafe', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text('${totalDistance.toStringAsFixed(2)} km'),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                leading: const Icon(Icons.speed, color: Colors.deepOrange),
                                title: const Text('Ortalama Hız', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text('${activity.averageSpeed} km/s'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}