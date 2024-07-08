import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Eğer kullanıcı giriş yapmamışsa, uygun şekilde yönetin (örneğin, giriş ekranını gösterin)
      return Scaffold(
        appBar: AppBar(
          title: Text('Aktivite Detayı'),
        ),
        body: Center(
          child: Text('Kullanıcı girişi gereklidir.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivite Detayı'),
      ),
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

          // Aktivite verilerini al
          Map<String, dynamic> data = snapshot.data!.data()!;
          Timestamp startTimeStamp = data['startTime'];
          DateTime startTime = startTimeStamp.toDate();
          Timestamp endTimeStamp = data['endTime'];
          DateTime? endTime = endTimeStamp != null ? endTimeStamp.toDate() : null;
          double totalDistance = data['totalDistance'] ?? 0.0;

          // Route verisini güvenli bir şekilde al
          List<GeoPoint>? routeGeoPoints = data['route'] != null
              ? List<GeoPoint>.from(data['route'])
              : null;
          List<LatLng> route = routeGeoPoints?.map((geoPoint) => LatLng(geoPoint.latitude, geoPoint.longitude)).toList() ?? [];

          // Harita üzerinde polylines oluştur
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: route.isNotEmpty ? route.first : LatLng(0, 0), // Default location if route is empty
                    zoom: 15,
                  ),
                  myLocationEnabled: false,
                  polylines: polylines,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(Icons.timer, color: Colors.blue),
                          title: Text('Başlangıç Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                          subtitle: Text('${startTime.toLocal()}'),
                        ),
                        if (endTime != null)
                          ListTile(
                            leading: Icon(Icons.timer_off, color: Colors.red),
                            title: Text('Bitiş Tarihi', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                            subtitle: Text('${endTime.toLocal()}'),
                          ),
                        ListTile(
                          leading: Icon(Icons.directions_walk, color: Colors.green),
                          title: Text('Toplam Mesafe', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                          subtitle: Text('${totalDistance.toStringAsFixed(2)} km'),
                        ),
                        ListTile(
                          leading: Icon(Icons.speed, color: Colors.deepOrange),
                          title: Text('Ortalama Hız', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                          subtitle: Text('${data['averageSpeed']} km/s'),
                        ),
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
