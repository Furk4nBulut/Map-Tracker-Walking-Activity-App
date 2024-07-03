import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      Weather weather = await _wf.currentWeatherByCityName("Istanbul");
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print('Weather fetch error: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ModalRoute.of(context)?.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _buildBody(user),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody(User? user) {
    if (_weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUserInfo(user),
        Expanded(
          child: _selectedIndex == 0 ? _buildHomeScreen(user) : _buildSelectedScreen(user),
        ),
      ],
    );
  }

  Widget _buildUserInfo(User? user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (user != null)
            Column(
              children: [
                ListTile(
                  title: Text("Kullanıcı Adı: ${user.displayName ?? 'Bilinmiyor'}"),
                  subtitle: Text("Email: ${user.email}"),
                  leading: CircleAvatar(
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null ? const Icon(Icons.person) : null,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Giriş Yapılmadı"),
            ),
          _weatherAndTimeInfo(),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(User? user) {
    return Center(
      child: Text("Hoşgeldiniz, ${user?.displayName ?? 'Misafir'}"),
    );
  }

  Widget _buildSelectedScreen(User? user) {
    if (user != null) {
      switch (_selectedIndex) {
        case 1:
          return ProfilePage(user: user);
        default:
          return Container();
      }
    } else {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Giriş Yapılmadı"),
      );
    }
  }

  Widget _weatherAndTimeInfo() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10.0),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_weather?.weatherIcon != null)
                Image.network(
                  "http://openweathermap.org/img/wn/${_weather!.weatherIcon}@2x.png",
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    print("Error loading image: $exception");
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
                    _weather?.areaName ?? "Bilinmiyor",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_weather?.temperature?.celsius?.toInt() ?? "Bilinmiyor"}°",
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _weather?.weatherDescription ?? "Bilinmiyor",
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
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

