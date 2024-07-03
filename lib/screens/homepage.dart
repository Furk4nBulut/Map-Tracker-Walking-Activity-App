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
          _locationHeader(),
          const SizedBox(height: 8.0),
          _dateTimeInfo(),
          const SizedBox(height: 16.0),
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

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "Bilinmiyor",
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = _weather?.date ?? DateTime.now();
    return Text(
      DateFormat("h:mm a").format(now),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
