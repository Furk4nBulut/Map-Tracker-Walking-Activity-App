import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/model/activity_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import '../model/user_model.dart';
import 'package:map_tracker/widgets/admob_interstitial.dart';
import 'package:map_tracker/widgets/admob_banner.dart';
import 'package:map_tracker/services/ad_service.dart';
import 'package:map_tracker/widgets/app_banner_ad.dart';
import 'package:geolocator/geolocator.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    AdService.showInterstitialAd(context);
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Hata yönetimi
    }
  }

  Future<Activity?> _fetchActivity() async {
    final localActivity = await DatabaseHelper().getActivityById(widget.activityId);
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
        .doc(widget.activityId)
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

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}';
    } else if (minutes > 0) {
      return '${twoDigits(minutes)}:${twoDigits(secs)}';
    } else {
      return '${twoDigits(secs)}';
    }
  }

  String formatDurationWithUnit(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    List<String> parts = [];
    if (hours > 0) {
      parts.add('$hours ${LocaleKeys.hourUnit.tr()}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${LocaleKeys.minuteUnit.tr()}');
    }
    if (secs > 0 || parts.isEmpty) {
      parts.add('$secs ${LocaleKeys.secondUnit.tr()}');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Activity?>(
      future: _fetchActivity(),
      builder: (context, AsyncSnapshot<Activity?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomAppBar(title: LocaleKeys.activityDetailTitle.tr(), automaticallyImplyLeading: true),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: CustomAppBar(title: LocaleKeys.activityDetailTitle.tr(), automaticallyImplyLeading: true),
            body: Center(
              child: Text(LocaleKeys.noActivityFound.tr()),
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
          appBar: CustomAppBar(title: LocaleKeys.activityDetailTitle.tr(), automaticallyImplyLeading: true),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
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
                              await mapController.drawMultipleRoad([
                                osm.MultiRoadConfiguration(
                                  startPoint: route.first,
                                  destinationPoint: route.last,
                                  intersectPoints: route.length > 2 ? route.sublist(1, route.length - 1) : [],
                                ),
                              ]);
                            }
                          }
                          // Şu anki konumu marker olarak ekle
                          if (isReady && _currentPosition != null) {
                            await mapController.addMarker(
                              osm.GeoPoint(
                                latitude: _currentPosition!.latitude,
                                longitude: _currentPosition!.longitude,
                              ),
                              markerIcon: const osm.MarkerIcon(
                                icon: Icon(Icons.my_location, color: Colors.red, size: 40),
                              ),
                            );
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
                                      title: Text(LocaleKeys.startDateLabel.tr(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                      subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm').format(startTime)),
                                    ),
                                  ),
                                  if (endTime != null)
                                    Expanded(
                                      child: ListTile(
                                        leading: const Icon(Icons.timer_off, color: Colors.red),
                                        title: Text(LocaleKeys.endDateLabel.tr(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
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
                                      title: Text(LocaleKeys.distanceLabel.tr(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                      subtitle: Text('${totalDistance.toStringAsFixed(2)} ${LocaleKeys.kmUnit.tr()}'),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                                      title: Text(LocaleKeys.durationLabel.tr(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                                      subtitle: Text(formatDurationWithUnit(activity.elapsedTime)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: AppBannerAd(),
              ),
            ],
          ),
        );
      },
    );
  }
}