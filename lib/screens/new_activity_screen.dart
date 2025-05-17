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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewActivityScreen extends StatefulWidget {
  const NewActivityScreen({Key? key}) : super(key: key);

  @override
  _NewActivityScreenState createState() => _NewActivityScreenState();
}

class _NewActivityScreenState extends State<NewActivityScreen> {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _activityStarted = false;
  DateTime? _startTime;
  DateTime? _endTime;
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  double _averageSpeed = 0.0;
  Timer? _timer;
  List<osm.GeoPoint> _route = [];
  osm.MapController? _mapController;
  bool _mapInitialized = false;
  String? _errorMessage;

  LocalUser? _currentUser;
  User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
    _loadCurrentUser();
    _loadFirebaseUser();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationAndMap() async {
    try {
      // Check and request location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Konum servisleri devre dışı.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Konum izinleri reddedildi.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Konum izinleri kalıcı olarak reddedildi.');
        return;
      }

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Initialize map controller
      _mapController = osm.MapController(
        initPosition: osm.GeoPoint(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        ),
      );

      // Set map initialized flag
      setState(() {
        _mapInitialized = true;
        _errorMessage = null;
      });

      // Start listening to position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          if (_activityStarted) {
            _updateActivityStats(position);
            _updateRoute(position);
            _centerMapOnCurrentLocation();
          }
        });
      }, onError: (e) {
        setState(() => _errorMessage = 'Konum güncellenirken hata: $e');
      });
    } catch (e) {
      setState(() => _errorMessage = 'Konum veya harita başlatılırken hata: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await DatabaseHelper().getCurrentUser();
    setState(() {});
  }

  Future<void> _loadFirebaseUser() async {
    _firebaseUser = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  void _startActivity() {
    if (_currentPosition == null || _mapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita veya konum hazır değil.')),
      );
      return;
    }

    setState(() {
      _activityStarted = true;
      _startTime = DateTime.now();
      _totalDistance = 0.0;
      _elapsedSeconds = 0;
      _averageSpeed = 0.0;
      _route = [];
      _updateRoute(_currentPosition!);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        if (_totalDistance > 0 && _elapsedSeconds > 0) {
          _averageSpeed = _totalDistance / (_elapsedSeconds / 3600); // km/h
        }
      });
    });

    _centerMapOnCurrentLocation();
  }

  void _finishActivity() async {
    if (!_activityStarted) return;

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

      // Save to local database if LocalUser exists
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

      // Save to Firestore if FirebaseUser exists
      if (_firebaseUser != null) {
        activityId ??= ActivityService().generateUniqueId();
        await FirebaseFirestore.instance
            .collection('user')
            .doc(_firebaseUser!.uid)
            .collection('activities')
            .doc(activityId)
            .set({
          'startTime': _startTime,
          'endTime': _endTime,
          'totalDistance': _totalDistance,
          'elapsedTime': _elapsedSeconds,
          'averageSpeed': _averageSpeed,
          'startPositionLat': startPosition?.latitude,
          'startPositionLng': startPosition?.longitude,
          'endPositionLat': endPosition?.latitude,
          'endPositionLng': endPosition?.longitude,
          'route': _route
              .map((point) => {
            'lat': point.latitude,
            'lng': point.longitude,
          })
              .toList(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivite kaydedildi.')),
      );

      if (activityId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(activityId: activityId!),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivite kaydedilirken hata: $e')),
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
    if (_mapController == null) return;

    final newPoint = osm.GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    setState(() {
      _route.add(newPoint);
    });

    if (_route.length > 1) {
      try {
        await _mapController!.addMarker(
          newPoint,
          markerIcon: const osm.MarkerIcon(
            icon: Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
        );
        await _mapController!.drawRoad(
          _route[_route.length - 2],
          newPoint,
          roadType: osm.RoadType.foot,
          roadOption: const osm.RoadOption(
            roadColor: Colors.blue,
            roadWidth: 5,
          ),
        );
      } catch (e) {
        debugPrint('Error drawing route: $e');
      }
    }
  }

  void _centerMapOnCurrentLocation() async {
    if (_currentPosition == null || _mapController == null) return;

    try {
      await _mapController!.changeLocation(
        osm.GeoPoint(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        ),
      );
      await _mapController!.setZoom(zoomLevel: 15);
    } catch (e) {
      debugPrint('Error centering map: $e');
    }
  }

  Widget _buildMap() {
    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_mapInitialized || _mapController == null) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Expanded(
      child: osm.OSMFlutter(
        controller: _mapController!,
        osmOption: const osm.OSMOption(
          enableRotationByGesture: false,
          zoomOption: osm.ZoomOption(
            initZoom: 15,
            minZoomLevel: 10,
            maxZoomLevel: 18,
          ),
        ),
        mapIsLoading: const Center(child: CircularProgressIndicator()),
        onMapIsReady: (isReady) async {
          if (isReady && _currentPosition != null) {
            try {
              await _mapController!.enableTracking(enableStopFollow: false);
              await _mapController!.addMarker(
                osm.GeoPoint(
                  latitude: _currentPosition!.latitude,
                  longitude: _currentPosition!.longitude,
                ),
                markerIcon: const osm.MarkerIcon(
                  icon: Icon(Icons.my_location, color: Colors.blue, size: 40),
                ),
              );
            } catch (e) {
              debugPrint('Error on map ready: $e');
            }
          }
        },
      ),
    );
  }

  Widget _buildActivityStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
            '$_elapsedSeconds s',
            Icons.timer,
            Colors.blue,
          ),
          _buildDivider(),
          _buildStatItem(
            'Hız',
            '${_averageSpeed.toStringAsFixed(2)} km/h',
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
            onPressed: _activityStarted || !_mapInitialized ? null : _startActivity,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Yeni Aktivite"),
      body: Column(
        children: [
          const WeatherWidget(),
          _buildMap(),
          _buildActivityStats(),
          _buildActivityButtons(),
        ],
      ),
    );
  }
}