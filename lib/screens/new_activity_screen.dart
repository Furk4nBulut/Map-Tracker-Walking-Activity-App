import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/screens/activity_detail_screen.dart';
import 'package:map_tracker/screens/homepage.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'dart:async';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/screens/partials/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewActivityScreen extends StatefulWidget {
  const NewActivityScreen({Key? key}) : super(key: key);

  @override
  _NewActivityScreenState createState() => _NewActivityScreenState();
}

class _NewActivityScreenState extends State<NewActivityScreen> {
  Position? _currentPosition;
  late StreamSubscription<Position> _positionStream;
  bool _activityStarted = false;
  DateTime? _startTime;
  DateTime? _endTime;
  double _totalDistance = 0;
  int _elapsedSeconds = 0;
  double _averageSpeed = 0;
  Timer? _timer;
  List<osm.GeoPoint> _route = [];
  osm.MapController? _mapController;

  LocalUser? _currentUser;
  User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchWeatherData();
    _loadCurrentUser();
    _loadFirebaseUser();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      _currentPosition = await _getCurrentLocation();
      _mapController = osm.MapController(
        initPosition: _currentPosition != null
            ? osm.GeoPoint(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude)
            : osm.GeoPoint(latitude: 0, longitude: 0),
      );
      await _mapController?.setZoom(zoomLevel: 15);
      _positionStream = Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentPosition = position;
          if (_activityStarted) {
            _updateActivityStats(position);
            _updateRoute(position);
            _centerMapOnCurrentLocation();
          }
        });
      });
    } catch (e) {
      print('Error initializing location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bilgisi alınamadı.')),
      );
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Konum servisleri devre dışı.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Konum izinleri reddedildi.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Konum izinleri kalıcı olarak reddedildi.';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await DatabaseHelper().getCurrentUser();
    setState(() {});
  }

  Future<void> _loadFirebaseUser() async {
    _firebaseUser = FirebaseAuth.instance.currentUser;
  }

  void _startActivity() {
    setState(() {
      _activityStarted = true;
      _startTime = DateTime.now();
      _route.clear();
      _updateRoute(_currentPosition!);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          if (_totalDistance > 0) {
            _averageSpeed = _totalDistance / (_elapsedSeconds / 3600); // km/s
          }
        });
      });

      _centerMapOnCurrentLocation();
    });
  }

  void _finishActivity() async {
    setState(() {
      _activityStarted = false;
      _endTime = DateTime.now();
      _timer?.cancel();
    });

    osm.GeoPoint? startPosition = _route.isNotEmpty ? _route.first : null;
    osm.GeoPoint? endPosition = _route.isNotEmpty ? _route.last : null;

    if (_currentUser == null && _firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
      );
      return;
    }

    try {
      String? activityId;

      if (_currentUser != null) {
        activityId = await ActivityService().saveActivityToLocal(
          user: _currentUser!,
          startTime: _startTime!,
          endTime: _endTime!,
          totalDistance: _totalDistance,
          elapsedTime: _elapsedSeconds,
          averageSpeed: _averageSpeed,
          startPosition: startPosition,
          endPosition: endPosition,
          route: _route,
        );
      }

      if (_firebaseUser != null) {
        DocumentReference ref = await FirebaseFirestore.instance
            .collection('user')
            .doc(_firebaseUser!.uid)
            .collection('activities')
            .add({
          'startTime': _startTime,
          'endTime': _endTime,
          'totalDistance': _totalDistance,
          'elapsedTime': _elapsedSeconds,
          'startPositionLat': startPosition?.latitude,
          'startPositionLng': startPosition?.longitude,
          'endPositionLat': endPosition?.latitude,
          'endPositionLng': endPosition?.longitude,
          'route': _route.map((point) => {
            'lat': point.latitude,
            'lng': point.longitude,
          }).toList(),
          'averageSpeed': _averageSpeed,
        });

        activityId = ref.id;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivite tamamlandı. Veriler kaydedildi.')),
      );

      if (activityId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(activityId: activityId!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivite ID alınamadı, ana sayfaya yönlendiriliyorsunuz.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivite kaydedilirken bir hata oluştu: $e')),
      );
    }
  }

  void _updateActivityStats(Position position) {
    if (_route.isNotEmpty) {
      double distanceInMeters = Geolocator.distanceBetween(
        _route.last.latitude,
        _route.last.longitude,
        position.latitude,
        position.longitude,
      );
      setState(() {
        _totalDistance += distanceInMeters / 1000; // Convert to kilometers
      });
    }
  }

  void _updateRoute(Position position) async {
    final newPoint = osm.GeoPoint(latitude: position.latitude, longitude: position.longitude);
    setState(() {
      _route.add(newPoint);
    });
    if (_route.length > 1 && _mapController != null) {
      await _mapController!.drawRoad(
        _route.first,
        _route.last,
        roadType: osm.RoadType.foot,
        roadOption: const osm.RoadOption(
          roadColor: Colors.blue,
          roadWidth: 5,
        ),
      );
    }
  }

  Future<void> _fetchWeatherData() async {
    // Weather data fetching remains unchanged
  }

  Widget _buildMap() {
    return Expanded(
      child: Stack(
        children: [
          osm.OSMFlutter(
            controller: _mapController!,
            osmOption: const osm.OSMOption(),
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            onMapIsReady: (isReady) async {
              if (isReady && _currentPosition != null) {
                await _mapController!.enableTracking();
                await _mapController!.setZoom(zoomLevel: 15);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Yeni Aktivite"),
      body: _mapController == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          WeatherWidget(),
          _buildMap(),
          _buildActivityStats(),
          _buildActivityButtons(),
        ],
      ),
    );
  }

  void _centerMapOnCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.currentLocation();
      await _mapController!.setZoom(zoomLevel: 15);
    }
  }

  Widget _buildActivityStats() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Mesafe',
            '${_totalDistance.toStringAsFixed(2)} km',
            Icons.directions_walk,
            Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            'Süre',
            '$_elapsedSeconds saniye',
            Icons.timer,
            Colors.blue,
          ),
          _buildDivider(),
          _buildStatItem(
            'Hız',
            '${_averageSpeed.toStringAsFixed(2)} km/s',
            Icons.speed,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 100,
      width: 1,
      color: basarsoft_color,
      margin: const EdgeInsets.symmetric(horizontal: 25),
    );
  }

  Widget _buildActivityButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _activityStarted ? null : _startActivity,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Başlat'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: basarsoft_color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _activityStarted ? _finishActivity : null,
            icon: const Icon(Icons.stop),
            label: const Text('Bitir'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}