import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/services/local_db_service.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Activity?>(
      future: DatabaseHelper().getActivityById(activityId), // Fetch activity from local DB
      builder: (context, AsyncSnapshot<Activity?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
            body: Center(
              child: Text('Aktivite bulunamadı.'),
            ),
          );
        }

        Activity activity = snapshot.data!;
        DateTime startTime = activity.startTime!;
        DateTime? endTime = activity.endTime;
        double totalDistance = activity.totalDistance ?? 0.0;
        List<LatLng> route = activity.route ?? [];

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

        Set<Marker> markers = {};
        if (route.isNotEmpty) {
          markers.add(
            Marker(
              markerId: MarkerId('start'),
              position: route.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: 'Başlangıç'),
            ),
          );
          markers.add(
            Marker(
              markerId: MarkerId('end'),
              position: route.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: 'Bitiş'),
            ),
          );
        }

        String formattedStartTime = DateFormat('dd MMMM yyyy, HH:mm').format(startTime);
        String? formattedEndTime = endTime != null ? DateFormat('dd MMMM yyyy, HH:mm').format(endTime) : null;

        return Scaffold(
          appBar: CustomAppBar(title: 'Aktivite Detayı', automaticallyImplyLeading: true),
          body: Column(
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
                  markers: markers,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
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
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
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
                                subtitle: Text('${activity.averageSpeed} km/s'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
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
