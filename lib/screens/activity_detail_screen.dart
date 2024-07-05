import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  ActivityDetailScreen({required this.activityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivite Detayı'),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('user').doc(activityId).get(), // Belge yolu düzeltildi
        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error.toString()}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          var activityData = snapshot.data!.data() as Map<String, dynamic>;

          // Kontrol edelim ki activityData doğru şekilde alınmış ve beklenen alanlar var mı
          if (!activityData.containsKey('startPosition') || !activityData.containsKey('route')) {
            return Center(child: Text('Aktivite verileri eksik veya hatalı.'));
          }

          // Rota için LatLng listesi oluşturalım
          List<dynamic> routePoints = activityData['route'];
          List<LatLng> polylinePoints = routePoints.map((point) => LatLng(point['latitude'], point['longitude'])).toList();

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(activityData['startPosition']['latitude'], activityData['startPosition']['longitude']),
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: PolylineId('route'),
                      points: polylinePoints,
                      color: Colors.blue,
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Toplam Mesafe: ${activityData['totalDistance']} km'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Geçen Süre: ${activityData['elapsedTime']} saniye'),
              ),
            ],
          );
        },
      ),
    );
  }
}
