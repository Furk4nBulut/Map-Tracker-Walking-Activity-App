import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_tracker/model/user_model.dart';
import 'package:map_tracker/services/local_db_service.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/screens/partials/navbar.dart';

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
  List<LatLng> _route = [];
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  LocalUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchWeatherData();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      _currentPosition = await _getCurrentLocation();
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

    LatLng? startPosition = _route.isNotEmpty ? _route.first : null;
    LatLng? endPosition = _route.isNotEmpty ? _route.last : null;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
      );
      return;
    }

    try {
      await ActivityService().saveActivity(
        user: _currentUser!,
        startTime: _startTime!,
        endTime: _endTime!,
        totalDistance: _totalDistance,
        elapsedTime: _elapsedSeconds,
        startPosition: startPosition,
        endPosition: endPosition,
        route: _route,
        averageSpeed: _averageSpeed,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivite tamamlandı. Veriler kaydedildi.')),
      );

      Navigator.of(context).pop();
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

  void _updateRoute(Position position) {
    setState(() {
      _route.add(LatLng(position.latitude, position.longitude));
      _polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          points: _route,
          color: Colors.blue,
          width: 5,
        ),
      };
    });
  }

  Future<void> _fetchWeatherData() async {
    // Fetch weather data asynchronously
  }

  Widget _buildMap() {
    return Expanded(
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _currentPosition != null
                ? CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15,
            )
                : CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            myLocationEnabled: true,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _buildMarkers(), // Add markers for start and end points
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    if (_route.isNotEmpty) {
      markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: _route.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Start'),
        ),
      );
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: _route.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Finish'),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Yeni Aktivite"),
      body: Column(
        children: [
          WeatherWidget(), // Weather widget
          _buildMap(), // Integrated into the column
          _buildActivityStats(),
          _buildActivityButtons(),
        ],
      ),
    );
  }

  void _centerMapOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
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
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 4),
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
      color: basarsoft_color, // Adjust color to match your theme
      margin: const EdgeInsets.symmetric(horizontal: 25), // Add some horizontal margin
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
            icon: Icon(Icons.play_arrow),
            label: const Text('Başlat'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: basarsoft_color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _activityStarted ? _finishActivity : null,
            icon: Icon(Icons.stop),
            label: const Text('Bitir'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
