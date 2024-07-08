import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/screens/partials/appbar.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
        body: Center(
          child: Text('Kullanıcı girişi gereklidir.'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('activities')
            .doc(activityId)
            .get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Aktivite bulunamadı.'));
          }

          Map<String, dynamic> data = snapshot.data!.data()!;
          Timestamp startTimeStamp = data['startTime'];
          DateTime startTime = startTimeStamp.toDate();
          Timestamp endTimeStamp = data['endTime'];
          DateTime? endTime = endTimeStamp != null ? endTimeStamp.toDate() : null;
          double totalDistance = data['totalDistance'] ?? 0.0;

          List<GeoPoint>? routeGeoPoints = data['route'] != null
              ? List<GeoPoint>.from(data['route'])
              : null;
          List<LatLng> route = routeGeoPoints?.map((geoPoint) => LatLng(geoPoint.latitude, geoPoint.longitude)).toList() ?? [];

          Set<Polyline> polylines = {};
          if (route.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: PolylineId('route_$activityId'),
                points: route,
                color: Colors.blue,
                width: 5,
              ),
            );
          }

          // Format dates
          String formattedStartTime = DateFormat('dd MMMM yyyy, HH:mm').format(startTime);
          String? formattedEndTime = endTime != null ? DateFormat('dd MMMM yyyy, HH:mm').format(endTime) : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: route.isNotEmpty ? route.first : LatLng(0, 0),
                    zoom: 15,
                  ),
                  myLocationEnabled: false,
                  polylines: polylines,
                ),
              ),
              SizedBox(height: 0), // Added spacing between map and details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: Icon(Icons.timer, color: Colors.blue),
                                title: Text('Başlangıç Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedStartTime),
                              ),
                            ),
                            if (formattedEndTime != null)
                              Expanded(
                                child: ListTile(
                                  leading: Icon(Icons.timer_off, color: Colors.red),
                                  title: Text('Bitiş Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                  subtitle: Text(formattedEndTime),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8), // Added spacing between sections
                        Divider(),
                        SizedBox(height: 8), // Added spacing between sections
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: Icon(Icons.directions_walk, color: Colors.green),
                                title: Text('Toplam Mesafe', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text('${totalDistance.toStringAsFixed(2)} km'),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                leading: Icon(Icons.speed, color: Colors.deepOrange),
                                title: Text('Ortalama Hız', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                subtitle: Text('${data['averageSpeed']} km/s'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16), // Added spacing between sections
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
