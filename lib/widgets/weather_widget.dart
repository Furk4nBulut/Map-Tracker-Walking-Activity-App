import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_tracker/utils/constants.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Konum servisleri devre dışı.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Konum izinleri reddedildi.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Konum izinleri kalıcı olarak reddedildi.';
      });
      return;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Konum alınamadı: $e';
      });
      return;
    }

    await _fetchWeatherByLocation(position);
  }

  Future<void> _fetchWeatherByLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String country = placemark.country ?? "Bilinmeyen Ülke";
        String city = placemark.locality ?? "Bilinmeyen Şehir";
        String district = placemark.subLocality ?? "Bilinmeyen Bölge";

        _fetchWeather(country, city, district);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Konum belirlenemedi.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Konum alınırken hata oluştu: $e';
      });
    }
  }

  Future<void> _fetchWeather(String country, String city, String district) async {
    try {
      String location = "$district, $city, $country";
      Weather weather = await _wf.currentWeatherByCityName(location);
      setState(() {
        _weather = weather;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Hava durumu getirilirken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? _buildLoadingWidget()
        : _errorMessage != null
        ? _buildErrorWidget()
        : _buildWeatherWidget();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.redAccent.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchUserLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Tekrar Dene',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [basarsoft_color_light, basarsoft_color],
          ),
          boxShadow: [
            BoxShadow(
              color: basarsoft_color.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(12), // Optional: add border radius if needed
        ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_weather?.weatherIcon != null)
                    Image.network(
                      "http://openweathermap.org/img/wn/${_weather!.weatherIcon}@2x.png",
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        print("Error loading image: $exception");
                        return const Icon(Icons.error);
                      },
                      width: 50,
                      height: 50,
                    )
                  else
                    const Icon(Icons.error),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_weather?.areaName ?? "Unknown"}, ${_weather?.country ?? "Unknown"}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_weather?.temperature?.celsius?.toInt() ?? "Unknown"}° ${_weather?.weatherDescription ?? "Unknown"}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _fetchUserLocation,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat("h:mm a").format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat("EEEE, d MMMM y").format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // Add more widgets here as needed
            ],
          ),
        ],
      ),
    );
  }
}

