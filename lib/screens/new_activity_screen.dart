import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchWeatherData();
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
            _centerMapOnCurrentLocation(); // Center map on current location
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

  void _startActivity() {
    setState(() {
      _activityStarted = true;
      _startTime = DateTime.now();
      _route.clear();
      _updateRoute(_currentPosition!); // Safe to use ! here assuming _currentPosition is not null
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          if (_totalDistance > 0) {
            _averageSpeed = _totalDistance / (_elapsedSeconds / 3600); // km/s
          }
        });
      });

      // Center map on current location when activity starts
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

    try {
      await ActivityService().saveActivity(
        startTime: _startTime!,
        endTime: _endTime!,
        totalDistance: _totalDistance,
        elapsedTime: _elapsedSeconds,
        startPosition: startPosition,
        endPosition: endPosition,
        route: _route, // Rotayı Firestore'a kaydetmek için bu listeyi geçirin
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivite tamamlandı. Veriler kaydedildi.')),
      );

      Navigator.of(context).pop(); // Örnek olarak geri gitmek için
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Aktivite'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _centerMapOnCurrentLocation,
                    child: Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          _buildActivityStats(),
          WeatherWidget(), // Weather widget
          _buildActivityButtons(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _currentPosition != null
          ? CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 15,
      )
          : CameraPosition(
        target: LatLng(0, 0),
        zoom: 15,
      ),
      myLocationEnabled: true, // Enable user location tracking
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('Toplam Mesafe: ${_totalDistance.toStringAsFixed(2)} km'),
          Text('Geçen Süre: ${_elapsedSeconds} saniye'),
          Text('Ortalama Hız: ${_averageSpeed.toStringAsFixed(2)} km/s'),
        ],
      ),
    );
  }

  Widget _buildActivityButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _activityStarted ? null : _startActivity,
            child: const Text('Başlat'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: _activityStarted ? _finishActivity : null,
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}
