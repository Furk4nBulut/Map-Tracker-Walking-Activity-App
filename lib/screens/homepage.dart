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

  void _fetchWeather() async {
    Weather? weather = await _wf.currentWeatherByCityName("Istanbul");
    setState(() {
      _weather = weather;
    });
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
        title: Text("Map Tracker App"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
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
      return Center(child: CircularProgressIndicator());
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
                    backgroundImage: NetworkImage(user.photoURL ?? ""),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          if (user == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Add any additional widgets for the home screen here
      ],
    );
  }

  Widget _buildSelectedScreen(User? user) {
    if (user != null) {
      switch (_selectedIndex) {
        case 1:
          return ProfilePage(user: user);
        default:
          return Container(); // Handle other cases as needed
      }
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Giriş Yapılmadı"),
      );
    }
  }

  Widget _locationHeader() {
    return Text(
      _weather!.areaName ?? "Bilinmiyor",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = _weather!.date!;
    return Text(
      DateFormat("h:mm a").format(now),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
