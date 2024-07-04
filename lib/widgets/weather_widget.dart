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
    return Center(
      child: _buildWeatherWidget(),
    );
  }

  Widget _buildWeatherWidget() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchUserLocation,
            child: const Text('Tekrar Dene'),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_weather?.weatherIcon != null)
                Image.network(
                  "http://openweathermap.org/img/wn/${_weather!.weatherIcon}@2x.png",
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    print("Resim yüklenirken hata: $exception");
                    return const Icon(Icons.error);
                  },
                )
              else
                const Icon(Icons.error),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_weather?.areaName ?? "Bilinmeyen"}, ${_weather?.country ?? "Bilinmeyen"}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_weather?.temperature?.celsius?.toInt() ?? "Bilinmeyen"}° ${_weather?.weatherDescription ?? "Bilinmeyen"}",
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            width: MediaQuery.of(context).size.width * 0.6,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                DateFormat("h:mm a").format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat("EEEE, d MMMM y").format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
