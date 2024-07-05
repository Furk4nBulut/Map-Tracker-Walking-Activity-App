import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, handle appropriately (e.g., show login screen)
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
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Aktivite bulunamadı.'));
          }

          var activityData = snapshot.data!.data() as Map<String, dynamic>;

          Timestamp startTimeStamp = activityData['startTime'];
          DateTime startTime = startTimeStamp.toDate();
          double totalDistance = activityData['totalDistance'] ?? 0.0;
          int elapsedTime = activityData['elapsedTime'] ?? 0;
          List<dynamic> routeCoordinates = activityData['route'] ?? [];

          List<LatLng> route = routeCoordinates.map((coord) {
            return LatLng(coord['latitude'], coord['longitude']);
          }).toList();

          Set<Polyline> _polylines = {
            Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: route,
            ),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: route.isNotEmpty ? route.first : LatLng(0, 0),
                    zoom: 15,
                  ),
                  polylines: _polylines,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Başlangıç Zamanı: ${startTime.toString()}'),
                    Text('Toplam Mesafe: ${totalDistance.toStringAsFixed(2)} km'),
                    Text('Geçen Süre: ${Duration(seconds: elapsedTime).toString()}'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
