import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_tracker/services/activity_service.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewActivityScreen extends StatefulWidget {
  const NewActivityScreen({Key? key}) : super(key: key);

  @override
  _NewActivityScreenState createState() => _NewActivityScreenState();
}

class _NewActivityScreenState extends State<NewActivityScreen> {
  late Position _currentPosition;
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
    _getCurrentLocation();
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum servisleri devre dışı.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izinleri reddedildi.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Konum izinleri kalıcı olarak reddedildi.')),
      );
      return;
    }

    _positionStream = Geolocator.getPositionStream(
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        if (_activityStarted) {
          _updateActivityStats(position);
          _updateRoute(position);
        }
      });
    });
  }

  void _startActivity() {
    setState(() {
      _activityStarted = true;
      _startTime = DateTime.now();
      _route.clear();
      _updateRoute(_currentPosition);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          _averageSpeed = _totalDistance / (_elapsedSeconds / 3600); // km/s
        });
      });
    });
  }

  void _finishActivity() async {
    setState(() {
      _activityStarted = false;
      _endTime = DateTime.now();
      _timer?.cancel();
    });

    ActivityService().saveActivity(
      startTime: _startTime!,
      endTime: _endTime!,
      totalDistance: _totalDistance,
      elapsedTime: _elapsedSeconds,
      startPosition: _currentPosition,
      endPosition: _currentPosition,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aktivite tamamlandı. Veriler kaydedildi.')),
    );
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
        _totalDistance += distanceInMeters / 1000; // km
      });
    }
  }

  void _updateRoute(Position position) {
    setState(() {
      _route.add(LatLng(position.latitude, position.longitude));
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: _route,
        width: 4,
        color: Colors.blue,
      ));
    });
  }

  Future<void> _fetchWeatherData() async {
    // Weather data fetching logic using the current location
    // Example: OpenWeatherMap API call
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
          WeatherWidget(), // Hava durumu widget'ı
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _route.isEmpty ? LatLng(0, 0) : _route.first,
                zoom: 15,
              ),
              myLocationEnabled: true,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Toplam Mesafe: ${_totalDistance.toStringAsFixed(2)} km',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Geçen Süre: ${_elapsedSeconds} saniye',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Ortalama Hız: ${_averageSpeed.toStringAsFixed(2)} km/s',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _activityStarted ? _finishActivity : _startActivity,
            child: Text(
                _activityStarted ? 'Aktiviteyi Bitir' : 'Aktiviteyi Başlat'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
