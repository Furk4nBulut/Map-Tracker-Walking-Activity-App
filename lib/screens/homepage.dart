import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_tracker/widgets/weather_widget.dart';
import 'package:map_tracker/screens/profile_screen.dart';
import 'package:map_tracker/screens/new_activity_screen.dart';
import 'package:map_tracker/screens/activity_record_screen.dart';
import 'package:map_tracker/screens/partials/navbar.dart'; // Import the BottomNavBar widget
import 'package:map_tracker/screens/partials/appbar.dart'; // Import the CustomAppBar widget
import 'package:map_tracker/screens/stat_page.dart'; // Import the ActivityHistoryScreen widget

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      if (_selectedIndex != 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewActivityScreen()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
            ? CustomAppBar(
          title: "Ana Sayfa",
          automaticallyImplyLeading: false,
        )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(user),
            StatisticPage(user: user!),

            NewActivityScreen(),

            ActivityHistoryScreen(),
            ProfilePage(user: user!),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,

        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: WeatherWidget(),
    );
  }
}
