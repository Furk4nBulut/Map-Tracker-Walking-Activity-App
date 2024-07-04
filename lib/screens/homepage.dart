import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _firebaseAuth.currentUser;

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? AppBar(
          title: const Text("Ana Sayfa"),
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
        )
            : null,
        body: _selectedIndex == 0 ? _buildHomeScreen(user) : ProfilePage(user: user!),
        bottomNavigationBar: SafeArea(
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.plus_one),
                label: 'Aktivite Ekle',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Aktivite Geçmişi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        extendBody: true,
      ),
    );
  }

  Widget _buildHomeScreen(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUserInfo(user),
        Expanded(
          child: Center(
            child: Text("Hoşgeldiniz, ${user?.displayName ?? 'Misafir'}"),
          ),
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
                const SizedBox(height: 1.0),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Giriş Yapılmadı"),
            ),
          _buildWeatherWidget(),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: WeatherWidget(),
    );
  }
}
